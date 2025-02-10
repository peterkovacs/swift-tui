@MainActor
@propertyWrapper
public struct FocusState<Value: Hashable>: DynamicProperty {
    public let initialValue: Value
    private let reference: DynamicPropertyReference<Value>

    public init() where Value == Bool {
        self.initialValue = false
        self.reference = .init()
    }

    public init<T>(wrappedValue initialValue: T) where Value == T?, T: Hashable {
        self.initialValue = initialValue
        self.reference = .init()
    }

    public var wrappedValue: Value {
        get { reference.wrappedValue ?? initialValue }
        nonmutating set { reference.wrappedValue = newValue }
    }

    public var projectedValue: Binding {
        .init {
            reference.wrappedValue ?? initialValue
        } set: { newValue in
            reference.wrappedValue = newValue
        }

    }

    func setup(node: DynamicPropertyNode, label: String) {
        reference.node = node
        reference.label = label
    }

    @MainActor
    public struct Binding {
        let get: @MainActor () -> Value?
        let set: @MainActor (Value?) -> Void

        init(get: @escaping @MainActor () -> Value?, set: @escaping @MainActor (Value?) -> Void) {
            self.get = get
            self.set = set
        }

        public var wrappedValue: Value? {
            get { get() }
            nonmutating set { set(newValue) }
        }

        public var projectedValue: Binding { self }
    }
}

extension FocusState: Sendable where Value: Sendable {}
