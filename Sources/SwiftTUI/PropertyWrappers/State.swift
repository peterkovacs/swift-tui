@MainActor
@propertyWrapper
public struct State<Wrapped>: DynamicProperty {
    public let initialValue: Wrapped
    private let reference: DynamicPropertyReference<Wrapped>

    public init(initialValue: Wrapped) {
        self.initialValue = initialValue
        self.reference = .init()
    }

    public init (wrappedValue: Wrapped) {
        self.initialValue = wrappedValue
        self.reference = .init()
    }


    public var wrappedValue: Wrapped {
        get { reference.wrappedValue ?? initialValue }
        nonmutating set { reference.wrappedValue = newValue }
    }

    public var projectedValue: Binding<Wrapped> {
        .init {
            wrappedValue
        } set: {
            wrappedValue = $0
        }
    }

    func setup(node: DynamicPropertyNode, label: String) {
        reference.initialize(node: node, label: label, value: initialValue)
    }
}

extension State: Sendable where Wrapped: Sendable {}
extension State where Wrapped: ExpressibleByNilLiteral {
    @inlinable public init() {
        self.init(wrappedValue: nil as Wrapped)
    }
}

@MainActor
class DynamicPropertyReference<Wrapped> {
    struct Key: Hashable {
        let type: ObjectIdentifier
        let label: String

        init(label: String) {
            self.type = ObjectIdentifier(Wrapped.self)
            self.label = label
        }
    }

    weak var node: DynamicPropertyNode?
    var label: String?

    var wrappedValue: Wrapped? {
        get {
            guard let node, let label else { fatalError("Accessed State prior to initialization") }
            return node.get(state: Key(label: label))
        }

        set {
            guard let node, let label else { fatalError("Accessed State prior to initialization") }
            node.set(state: Key(label: label), value: newValue)
        }
    }

    func initialize(node: DynamicPropertyNode, label: String, value: Wrapped) {
        self.node = node
        self.label = label
        let key = Key(label: label)
        node.state[key] = node.state[key] ?? value
    }
}
