extension View {
    func focusable(_ isFocusable: Bool) -> some View {
        FocusableView(isFocusable: isFocusable, content: self)
    }
}

struct FocusableView<Content: View>: View, PrimitiveView {
    let isFocusable: Bool
    let content: Content

    func build(parent: Node?) -> Node {
        let node = FocusableNode(
            view: self,
            parent: parent,
            isFocusable: isFocusable
        )

        node.add(at: 0, node: content.view.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let focusableNode = node as? FocusableNode else {
            fatalError("Unexpected node type: \(type(of: node))")
        }
        
        focusableNode.isFocusable = isFocusable
        focusableNode.children[0].update(view: content.view)
    }
}

final class FocusableNode: Node {
    var isFocusable: Bool {
        didSet {
            if oldValue != isFocusable {
                evaluate()
            }
        }
    }

    init(view: any GenericView, parent: Node?, isFocusable: Bool) {
        self.isFocusable = isFocusable
        super.init(view: view, parent: parent)
    }

    var _focusVisitor: FocusVisitor? = nil
    var focusVisitor: FocusVisitor {
        guard let _focusVisitor else {
            let visitor = FocusVisitor(children: children)
            _focusVisitor = visitor
            return visitor
        }

        return _focusVisitor
    }

    struct FocusVisitor: Visitor.Focus {
        var visited: [Visitor.FocusableElement]

        fileprivate init(
            children: [Node]
        ) {
            visited = []
            for child in children {
                child.focus(visitor: &self)
            }
        }

        mutating func visit(focus: Visitor.FocusableElement) {
            visited.append(focus)
        }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        for visited in focusVisitor.visited {
            visitor.visit(
                focus: .init(
                    node: visited.node
                ) { [weak self] in
                    self?.isFocusable ?? visited.isFocusable()
                } handle: { [weak self] key in
                    guard let self else { return false }
                    return isFocusable && visited.handle(key)
                } resignFirstResponder: {
                    visited.resignFirstResponder()
                } becomeFirstResponder: {
                    visited.becomeFirstResponder()
                }
            )
        }
    }

    override func invalidateLayout() {
        _focusVisitor = nil
        super.invalidateLayout()
    }

    func evaluate() {
        if !isFocusable, let focused = focusVisitor.visited.first(where: { $0.node.isFocused }) {
            root?.focusManager?.remove(focus: focused)
        }

        invalidateLayout()
    }
}
