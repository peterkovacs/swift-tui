// State.swift

@MainActor
@propertyWrapper
public struct State<Wrapped>: DynamicProperty {
    private let reference: DynamicPropertyReference<Wrapped>

    public init(initialValue: Wrapped) {
        self.reference = .init(initialValue: initialValue)
    }

    public init(wrappedValue: Wrapped) {
        self.reference = .init(initialValue: wrappedValue)
    }

    public var wrappedValue: Wrapped {
        get { reference.wrappedValue }
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
        reference.initialize(node: node, label: label)
    }
}

extension State: Sendable where Wrapped: Sendable {}

extension State where Wrapped: ExpressibleByNilLiteral {
    @inlinable public init() {
        self.init(wrappedValue: nil as Wrapped)
    }
}

@MainActor
final class DynamicPropertyReference<Wrapped> {
    let initialValue: Wrapped

    struct Key: Hashable, Sendable {
        let type: ObjectIdentifier
        let label: String

        init(label: String) {
            self.type = ObjectIdentifier(Wrapped.self)
            self.label = label
        }
    }

    weak var node: DynamicPropertyNode?
    var label: String?

    init(initialValue: Wrapped) {
        self.initialValue = initialValue
    }

    var wrappedValue: Wrapped {
        get {
            // If not yet wired, surface the initial value without crashing.
            guard let node, let label else { return initialValue }
            let key = Key(label: label)
            if let existing: Wrapped = node.get(state: key) {
                return existing
            } else {
                node.set(state: key, value: initialValue)
                return initialValue
            }
        }
        set {
            // If not yet wired, ignore the set until setup; once wired, it will be seeded via initialize.
            guard let node, let label else { return }
            node.set(state: Key(label: label), value: newValue)
        }
    }

    func initialize(node: DynamicPropertyNode, label: String) {
        self.node = node
        self.label = label
        let key = Key(label: label)
        // Preserve existing value across re-renders; otherwise seed with initialValue.
        node.state[key] = node.state[key] ?? initialValue
    }
}

