extension View {
    func command(_ key: Key, isEnabled: Bool = true, action: @escaping @MainActor () -> Void) -> some View {
        Command(content: self, key: key, action: action, isEnabled: isEnabled)
    }
}

struct Command<Content: View>: View, PrimitiveView {
    let content: Content
    let key: Key
    let action: @MainActor () -> Void
    let isEnabled: Bool

    func build(parent: Node?) -> Node {
        let node = CommandNode(
            view: view,
            parent: parent,
            key: key,
            action: action,
            isEnabled: isEnabled
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let commandNode = node as? CommandNode else {
            fatalError("Unexpected node type: \(type(of: node))")
        }

        commandNode.key = key
        commandNode.action = action
        commandNode.isEnabled = isEnabled

        node.children[0].update(view: content.view)
    }
}

final class CommandNode: Node {
    var key: Key
    var action: @MainActor () -> Void
    var isEnabled: Bool

    init(
        view: any GenericView,
        parent: Node?,
        key: Key,
        action: @escaping @MainActor () -> Void,
        isEnabled: Bool
    ) {
        self.key = key
        self.action = action
        self.isEnabled = isEnabled
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
        // TODO: Do we want this to be focusable if it has no focusable children?
        for visited in focusVisitor.visited {
            visitor.visit(
                focus: .init(node: visited.node) {
                    visited.isFocusable()
                } handle: { [weak self] input in
                    guard let self, isEnabled, key == input else {
                        return visited.handle(input)
                    }

                    action()
                    return true

                } resignFirstResponder: {
                    visited.resignFirstResponder()
                } becomeFirstResponder: {
                    visited.becomeFirstResponder()
                }
            )
        }
    }
}
