/// Manages keyboard and pointer focus within a subtree of the node hierarchy.
///
/// `FocusManager` maintains the ordered list of focusable elements discovered by
/// traversing a given `Node` subtree and tracks which element is currently focused.
/// It coordinates first-responder changes by calling `becomeFirstResponder()` and
/// `resignFirstResponder()` on focusable elements as focus moves.
///
/// Key responsibilities:
/// - Establishes a default focus using the first focusable element when requested.
/// - Handles focus traversal for Tab and Shift-Tab, with optional wrap-around when
///   managing the root focus scope.
/// - Forwards input to the currently focused element and consumes events that it
///   handles.
/// - Re-evaluates focus when the view/node tree changes, preserving focus when
///   possible (accounting for inserts, moves, and removals), or selecting a new
///   default when the focused element disappears.
///
/// Concurrency:
/// - Marked `@MainActor` because it coordinates UI state and interacts with nodes
///   that are expected to be used on the main thread.
@MainActor
class FocusManager {
    private var isRoot: Bool
    private var evaluatingFocus: Bool = false
    private var focusVisitor: FocusVisitor
    private var focusedElementIndex: Array<Visitor.FocusableElement>.Index? {
        didSet {
            if !evaluatingFocus {
                if let oldValue {
                    focusVisitor.visited[oldValue].resignFirstResponder()
                } else if let parent {
                    // if there was no focus prior, then we need to inform the parent that this FocusManager now has the focus.
                }
                focusedElementIndex.map { focusVisitor.visited[$0] }?.becomeFirstResponder()
            }
        }
    }
    private var parent: FocusManager? = nil

    var focusedElement: Visitor.FocusableElement? {
        focusedElementIndex.map { focusVisitor.visited[$0]}
    }

    init(root: Node) {
        // TODO: Deal with prefersDefaultFocus
        self.isRoot = true
        self.focusVisitor = .init(visiting: root)
        self.focusedElementIndex = nil
    }

    init(secondary root: Node, parent: FocusManager?) {
        // TODO: Deal with prefersDefaultFocus
        self.isRoot = false
        self.focusVisitor = .init(visiting: root)
        self.focusedElementIndex = nil
        self.parent = parent
    }

    func defaultFocus() {
        self.focusedElementIndex = self.focusVisitor.visited.firstIndex { $0.isFocusable() }
    }

    func handle(key: Key) -> Bool {
        guard focusedElement?.handle(key) != true else {
            return true
        }

        switch key {
        case .init(.tab, modifiers: []):
            guard let focusedElementIndex else {
                focusedElementIndex = focusVisitor.visited.firstIndex { $0.isFocusable() }
                return focusedElementIndex != nil
            }

            var nextIndex = focusedElementIndex

            repeat {
                nextIndex = focusVisitor.visited.index(after: nextIndex)
                if nextIndex == focusVisitor.visited.endIndex {
                    if isRoot {
                        nextIndex = focusVisitor.visited.startIndex
                    } else {
                        self.focusedElementIndex = nil
                        return false
                    }
                }
            } while nextIndex != focusedElementIndex && focusVisitor.visited[nextIndex].isFocusable() == false

            if nextIndex != focusedElementIndex {
                self.focusedElementIndex = nextIndex
                return true
            }

        case .init(.tab, modifiers: .shift):
            guard let focusedElementIndex else {
                focusedElementIndex = focusVisitor.visited.lastIndex { $0.isFocusable() }
                return focusedElementIndex != nil
            }

            var nextIndex = focusedElementIndex

            repeat {
                if nextIndex == focusVisitor.visited.startIndex {
                    if isRoot {
                        nextIndex = focusVisitor.visited.endIndex
                    } else {
                        self.focusedElementIndex = nil
                        return false
                    }
                }
                nextIndex = focusVisitor.visited.index(before: nextIndex)
            } while nextIndex != focusedElementIndex && focusVisitor.visited[nextIndex].isFocusable() == false

            if nextIndex != focusedElementIndex {
                self.focusedElementIndex = nextIndex
                return true
            }

        default: break

        }

        return false
    }

    func remove(focus: Visitor.FocusableElement?) {
        assert( focus?.node === self.focusedElement?.node )
        self.focusedElementIndex = nil
    }

    func change(focus: Visitor.FocusableElement?) {
        if let focus {
            guard let index = focusVisitor.visited.firstIndex(of: focus) else {
                assertionFailure("Changing focus to unknown element: \(focus)")
                return
            }

            self.focusedElementIndex = index
        } else {
            self.focusedElementIndex = nil
        }
    }

    func evaluate(focus node: Node) {
        let focusVisitor: FocusVisitor = .init(visiting: node)

        // There are 3 cases we need to handle:
        // 1. New elements are inserted into `visited` before focusedElementIndex
        // 2. focusedElementIndex moves to another spot in `visited`.
        // 3. The element that focusedElementIndex refers to is removed.

        var elementRemoved: Bool = false
        if let focusedElementIndex {
            let differences = focusVisitor.visited.difference(from: self.focusVisitor.visited).inferringMoves()

            var offset = 0
            var elementMovedTo: Int? = nil

            for difference in differences {
                switch difference {
                case let .insert(offset: i, element: _, associatedWith: nil):
                    offset += i <= (focusedElementIndex + offset) ? 1 : 0
                case let .insert(offset: i, element: _, associatedWith: .some(j)):
                    offset += i <= (focusedElementIndex + offset) && j > focusedElementIndex ? 1 : 0
                case .remove(offset: focusedElementIndex, element: _, associatedWith: let .some(i)):
                    elementMovedTo = i
                case .remove(offset: focusedElementIndex, element: _, associatedWith: nil):
                    elementRemoved = true

                case .remove(offset: let i, element: _, associatedWith: nil):
                    offset -= i < (focusedElementIndex + offset) ? 1 : 0
                case .remove(offset: let i, element: _, associatedWith: let .some(j)):
                    offset -= i < (focusedElementIndex + offset) && j > focusedElementIndex ? 1 : 0
                }
            }

            if let elementMovedTo {
                evaluatingFocus = true
                self.focusedElementIndex = elementMovedTo
                evaluatingFocus = false
            } else if elementRemoved {
                self.focusedElementIndex = nil
            } else {
                evaluatingFocus = true
                self.focusedElementIndex = focusedElementIndex + offset
                evaluatingFocus = false
            }
        }

        self.focusVisitor = focusVisitor
        if elementRemoved, focusedElementIndex == nil {
            focusedElementIndex = focusVisitor.visited.firstIndex { $0.isFocusable() }
        }
    }

    struct FocusVisitor: Visitor.Focus {
        var visited: [Visitor.FocusableElement]

        init(visiting node: Node) {
            self.visited = []

            for child in node.children {
                child.focus(visitor: &self)
            }
        }

        mutating func visit(focus element: Visitor.FocusableElement) {
            visited.append(element)
        }
    }
}

