@MainActor
@propertyWrapper
public struct State<Wrapped>: StateValue {
    public let initialValue: Wrapped

    public init(initialValue: Wrapped) {
        self.initialValue = initialValue
        self.reference = .init()
    }

    public init (wrappedValue: Wrapped) {
        self.initialValue = wrappedValue
        self.reference = .init()
    }

    var reference: StateReference<Wrapped>

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

    func setup(node: ComposedNode, label: String) {
        reference.node = node
        reference.label = label
    }
}

@MainActor
protocol StateValue {
    associatedtype Wrapped
    var wrappedValue: Wrapped { get nonmutating set }
    var projectedValue: Binding<Wrapped> { get }
    func setup(node: ComposedNode, label: String)
}

@MainActor
class StateReference<Wrapped> {
    weak var node: ComposedNode?
    var label: String?

    var wrappedValue: Wrapped? {
        get {
            guard let node, let label else { fatalError("Accessed State prior to initialization") }
            return node.state[label] as? Wrapped
        }

        set {
            guard let node, let label else { fatalError("Accessed State prior to initialization") }
            node.state[label] = newValue
            node.invalidate()
        }
    }
}
