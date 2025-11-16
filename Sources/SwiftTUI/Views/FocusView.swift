extension View {

    /// Sets focus to this view when the bound `FocusState<Bool>` becomes `true`, and clears it when set to `false`.
    ///
    /// Use this overload when you model focus as a simple on/off state.
    /// - Parameter binding: A binding to a `FocusState<Bool>` that controls whether this view is focused.
    /// - Returns: A view that participates in focus management, becoming first responder when `binding.wrappedValue` is `true`.
    ///
    /// Behavior:
    /// - When `binding` becomes `true`, this view requests focus.
    /// - When the view loses focus (e.g., user tabs away), `binding` is set to `false`.
    /// - When `binding` is set to `false`, the view relinquishes focus if it has it.
    ///
    /// Example:
    /// ```swift
    /// @FocusState private var isFocused: Bool
    ///
    /// TextField("Name", text: $name)
    ///     .focus($isFocused) // Focus toggles based on `isFocused`
    /// ```
    ///
    /// Notes:
    /// - If no focusable descendants exist, the binding will be set back to `false`.
    /// - Focus changes are coordinated by the environment’s `FocusManager`.
    public func focus(_ binding: FocusState<Bool>.Binding) -> some View {
        FocusView<Self, Bool>(
            binding: binding,
            value: true,
            content: self
        )
    }

    /// Associates this view’s focus with a specific value of an optional `FocusState`,
    /// setting focus when the bound value equals `equals`, and clearing it when it differs (including `nil`).
    ///
    /// Use this overload when you model focus across multiple views using a single optional enum or identifier.
    /// - Parameters:
    ///   - binding: A binding to a `FocusState<Value?>` that tracks which view (if any) is focused.
    ///   - equals: The value that represents focus for this view.
    /// - Returns: A view that participates in focus management, becoming first responder when `binding.wrappedValue == equals`.
    ///
    /// Behavior:
    /// - When `binding` is set to `equals`, this view requests focus.
    /// - When the view becomes focused, `binding` is set to `equals`.
    /// - When the view loses focus, `binding` is set to `nil` (or any non-equal value).
    ///
    /// Example:
    /// ```swift
    /// enum Field: Hashable { case username, password }
    /// @FocusState private var focusedField: Field?
    ///
    /// TextField("Username", text: $username)
    ///     .focus($focusedField, equals: .username)
    ///
    /// SecureField("Password", text: $password)
    ///     .focus($focusedField, equals: .password)
    /// ```
    ///
    /// Notes:
    /// - If no focusable descendants exist, the binding will be set to `nil`.
    /// - This enables mutually exclusive focus between multiple views bound to the same `FocusState`.
    public func focus<Value: Hashable>(
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

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = FocusNode(
            view: self,
            parent: parent,
            root: root,
            binding: binding,
            value: value,
            unset: unset
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
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
        root: RootNode?,
        binding: FocusState<Value>.Binding,
        value: Value,
        unset: Value
    ) {
        self.binding = binding
        self.previousValue = binding.wrappedValue
        self.value = value
        self.unset = unset
        super.init(view: view, parent: parent, root: root)
    }

    func evaluate(value: Value, binding: FocusState<Value>.Binding) {
        let focusable = focusVisitor.visited.filter { $0.isFocusable() }
        let isFocused = focusable.contains { $0.node.isFocused }

        if !isFocused, value == binding.wrappedValue {
            if !isFocused, let focus = focusable.first {
                root?.focusManager?.change(focus: focus)
            } else {
                // There's nothing to focus within this hierarchy, write the `unset` value back to the binding.
                binding.wrappedValue = unset
            }
        } else if isFocused, unset == binding.wrappedValue {
            root?.focusManager?.remove(focus: focusable.first { $0.node.isFocused })
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
