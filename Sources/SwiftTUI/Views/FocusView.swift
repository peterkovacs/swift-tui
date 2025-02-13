extension View {
    func focus(_ binding: FocusState<Bool>.Binding) -> some View {
        FocusView<Self, Bool>(
            binding: binding,
            value: true,
            content: self
        )
    }

    func focus<Value: Hashable>(
        _ binding: FocusState<Value?>.Binding,
        equals: Value
    ) -> some View {
        FocusView(
            binding: binding,
            value: equals,
            content: self
        )
    }
}

struct FocusView<Content: View, Value: Hashable>: View, PrimitiveView {
    var binding: FocusState<Value>.Binding
    var value: Value
    var unset: Value
    var content: Content

    init(binding: FocusState<Value>.Binding, value: Value, content: Content) where Value == Bool {
        self.binding = binding
        self.value = value
        self.content = content
        self.unset = false
    }

    init<T>(binding: FocusState<Value>.Binding, value: T, content: Content) where Value == T? {
        self.binding = binding
        self.value = value
        self.content = content
        self.unset = nil
    }

    func build(parent: Node?) -> Node {
        let node = FocusNode(
            view: self,
            parent: parent,
            binding: binding,
            value: value,
            unset: unset
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? FocusNode<Value> else {
            fatalError("Unexpected node type \(String(describing: type(of: node)))")
        }

        node.view = self
        node.children[0].update(view: content.view)
        node.evaluate(value: value, binding: binding)
    }
}

final class FocusNode<Value: Hashable>: Node {
    var binding: FocusState<Value>.Binding
    var value: Value
    var unset: Value
    var previousValue: Value

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

    init(
        view: any GenericView,
        parent: Node?,
        binding: FocusState<Value>.Binding,
        value: Value,
        unset: Value
    ) {
        self.binding = binding
        self.previousValue = binding.wrappedValue
        self.value = value
        self.unset = unset
        super.init(view: view, parent: parent)
    }

    func evaluate(value: Value, binding: FocusState<Value>.Binding) {
        let focusable = focusVisitor.visited.filter { $0.isFocusable() }
        let isFocused = focusable.contains { $0.node.isFocused }

        if !isFocused, value == binding.wrappedValue {
            if !isFocused, let focus = focusable.first {
                application?.focusManager.change(focus: focus)
            } else {
                binding.wrappedValue = unset
            }
        } else if isFocused, unset == binding.wrappedValue {
            application?.focusManager.remove(focus: focusable.first { $0.node.isFocused })
            binding.wrappedValue = unset
        }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        for visited in focusVisitor.visited {
            visitor.visit(
                focus: .init(node: visited.node) {
                    visited.isFocusable()
                } handle: { key in
                    return visited.handle(key)
                } resignFirstResponder: { [weak self] in
                    guard let self else { return }
                    binding.wrappedValue = unset
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

    override var description: String {
        let expected, actual: Any

        do {
            let binding = binding.wrappedValue
            let mirror = Mirror(reflecting: binding)
            let child = mirror.children.first
            actual = child?.value ?? "(nil)" as Any
        }

        do {
            let mirror = Mirror(reflecting: value)
            let children = mirror.children
            guard let child = children.first else { return super.description }

            expected = child.value
        }

        return "\(super.description): \(expected) \(binding.wrappedValue == value ? "==" : "!=") \(actual)"
    }
}
