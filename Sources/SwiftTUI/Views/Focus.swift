extension View {
    func focus(_ binding: FocusState<Bool>.Binding) -> some View {
        focus(binding, equals: true)
    }

    func focus<Value>(_ binding: FocusState<Value>.Binding, equals: Value) -> some View where Value: Hashable {
        SetFocusView(binding: binding, value: equals, content: self)
    }

    func focusable(_ isFocusable: Bool) -> some View {
        EmptyView()
    }
}

struct SetFocusView<Content: View, Value: Hashable>: View, PrimitiveView {
    var binding: FocusState<Value>.Binding
    var value: Value
    var content: Content

    init(binding: FocusState<Value>.Binding, value: Value, content: Content) {
        self.binding = binding
        self.value = value
        self.content = content
    }

    func build(parent: Node?) -> Node {
        let node = SetFocusNode(
            view: self,
            parent: parent,
            binding: binding,
            value: value
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? SetFocusNode<Value> else {
            fatalError("Unexpected node type \(String(describing: type(of: node)))")
        }

        node.view = self
        node.children[0].update(view: content.view)
        node.evaluate(value: value, binding: binding)
    }
}

final class SetFocusNode<Value: Hashable>: Node {
    var binding: FocusState<Value>.Binding
    var value: Value
    var previousValue: Value?

    var _focusVisitor: FocusManager.FocusVisitor? = nil
    var focusVisitor: FocusManager.FocusVisitor {
        if let visitor = _focusVisitor {
            return visitor
        } else {
            let visitor = FocusManager.FocusVisitor(visiting: self)
            _focusVisitor = visitor
            return visitor
        }
    }

    init<T: View>(view: T, parent: Node?, binding: FocusState<Value>.Binding, value: Value) {
        self.binding = binding
        self.value = value
        super.init(view: view.view, parent: parent)
        evaluate(value: value, binding: binding)
    }

    func evaluate(value: Value, binding: FocusState<Value>.Binding) {
        defer {
            self.previousValue = binding.wrappedValue
            self.value = value
            self.binding = binding
        }

        switch (previousValue, binding.wrappedValue) {
        case (.some(value), .some(value)): break
        case (.some(value), .none):
            // find the item that has focus and remove.
            application?.focusManager.remove(
                focus: focusVisitor.visited.first { $0.node.isFocused }
            )
        case (_, .some(value)):
            application?.focusManager.change(
                focus: focusVisitor.visited.first { $0.isFocusable() }
            )
        case (_, _): break
        }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        for visited in focusVisitor.visited {
            visitor.visit(
                focus: .init(node: visited.node) {
                    visited.isFocusable()
                } resignFirstResponder: { [weak self] in
                    guard let self else { return }
                    binding.wrappedValue = nil
                    visited.resignFirstResponder()
                } becomeFirstResponder: { [weak self] in
                    guard let self else { return }
                    binding.wrappedValue = value
                    visited.becomeFirstResponder()
                }
            )
        }
    }

    override func invalidateLayout() {
        _focusVisitor = nil
        super.invalidateLayout()
    }

}
