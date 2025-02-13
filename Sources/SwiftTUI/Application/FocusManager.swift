@MainActor
class FocusManager {
    private var evaluatingFocus: Bool = false
    private var focusVisitor: FocusVisitor
    private var focusedElementIndex: Array<Visitor.FocusableElement>.Index? {
        didSet {
            if !evaluatingFocus {
                oldValue.map { focusVisitor.visited[$0] }?.resignFirstResponder()
                focusedElementIndex.map { focusVisitor.visited[$0] }?.becomeFirstResponder()
            }
        }
    }

    var focusedElement: Visitor.FocusableElement? {
        focusedElementIndex.map { focusVisitor.visited[$0]}
    }

    init(root: Node) {
        // TODO: Deal with prefersDefaultFocus

        self.focusVisitor = .init(visiting: root)
        self.focusedElementIndex = nil
    }

    func defaultFocus() {
        self.focusedElementIndex = self.focusVisitor.visited.firstIndex { $0.isFocusable() }
    }

    func handle(key: Key) -> Bool {
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
                    nextIndex = focusVisitor.visited.startIndex
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
                    nextIndex = focusVisitor.visited.endIndex
                }
                nextIndex = focusVisitor.visited.index(before: nextIndex)
            } while nextIndex != focusedElementIndex && focusVisitor.visited[nextIndex].isFocusable() == false

            if nextIndex != focusedElementIndex {
                self.focusedElementIndex = nextIndex
                return true
            }

        default: break

        }

        return focusedElement?.handle(key) ?? false
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
