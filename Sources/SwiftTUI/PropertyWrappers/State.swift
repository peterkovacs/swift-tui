@MainActor
@propertyWrapper
public struct State<Wrapped>: StateValue, DynamicProperty {
    public let initialValue: Wrapped

    public init(initialValue: Wrapped) {
        self.initialValue = initialValue
        self.reference = .init()
    }

    public init (wrappedValue: Wrapped) {
        self.initialValue = wrappedValue
        self.reference = .init()
    }

    let reference: StateReference<Wrapped>

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
        reference.node = node
        reference.label = label
    }
}

extension State: Sendable where Wrapped: Sendable {}
extension State where Wrapped: ExpressibleByNilLiteral {
    @inlinable public init() {
        self.init(wrappedValue: nil as Wrapped)
    }
}

@MainActor
protocol StateValue {
    associatedtype Wrapped
    var wrappedValue: Wrapped { get nonmutating set }
    var projectedValue: Binding<Wrapped> { get }    
}

@MainActor
class StateReference<Wrapped> {
    struct Key: Hashable {
        let label: String
    }

    weak var node: DynamicPropertyNode?
    var label: String?

    var wrappedValue: Wrapped? {
        get {
            guard let node, let label else { fatalError("Accessed State prior to initialization") }
            return node.get(state: Key(label: label))
        }

        set {
            guard let node, let label, let newValue else { fatalError("Accessed State prior to initialization") }
            node.set(state: Key(label: label), value: newValue)
        }
    }
}
