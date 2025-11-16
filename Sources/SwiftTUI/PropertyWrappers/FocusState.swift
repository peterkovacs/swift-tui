@MainActor
@propertyWrapper
public struct FocusState<Value: Hashable>: DynamicProperty {
    private let reference: DynamicPropertyReference<Value>

    public init() where Value == Bool {
        self.reference = .init(initialValue: false)
    }

    public init<T>(wrappedValue initialValue: T?) where Value == T?, T: Hashable {
        self.reference = .init(initialValue: initialValue)
    }

    public var wrappedValue: Value {
        get { reference.wrappedValue }
        nonmutating set { reference.wrappedValue = newValue }
    }

    public var projectedValue: Binding {
        .init {
            wrappedValue
        } set: { newValue in
            if reference.wrappedValue != newValue {
                reference.wrappedValue = newValue
            }
        }
    }

    func setup(node: DynamicPropertyNode, label: String) {
        reference.initialize(node: node, label: label)
    }

    @MainActor
    public struct Binding {
        let get: @MainActor () -> Value
        let set: @MainActor (Value) -> Void

        init(get: @escaping @MainActor () -> Value, set: @escaping @MainActor (Value) -> Void) {
            self.get = get
            self.set = set
        }

        public var wrappedValue: Value {
            get { get() }
            nonmutating set { set(newValue) }
        }

        public var projectedValue: Binding { self }
    }
}

extension FocusState: Sendable where Value: Sendable {}
