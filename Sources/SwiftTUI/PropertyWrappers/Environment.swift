import Foundation

@MainActor
@propertyWrapper
public struct Environment<Wrapped>: EnvironmentValue {
    var reference: EnvironmentReference<Wrapped>

    public init(_ keyPath: KeyPath<EnvironmentValues, Wrapped>) {
        self.reference = .init(keyPath: keyPath)
    }

    public var wrappedValue: Wrapped {
        get { reference.wrappedValue }
    }

    func setup(node: Node) {
        reference.node = node
    }
}

@MainActor
protocol EnvironmentValue {
    associatedtype Wrapped
    var wrappedValue: Wrapped { get }
    func setup(node: Node)
}

@MainActor
class EnvironmentReference<Wrapped> {
    weak var node: Node?
    var keyPath: KeyPath<EnvironmentValues, Wrapped>

    init(keyPath: KeyPath<EnvironmentValues, Wrapped>) {
        self.keyPath = keyPath
    }

    var wrappedValue: Wrapped {
        guard let node else { fatalError("Accessed Environment prior to initialization") }
        let values = values(node: node) { _ in }
        return values[keyPath: keyPath]
    }

    private func values(
        node: Node,
        transform: (inout EnvironmentValues) -> Void
    ) -> EnvironmentValues {
        if let parent = node.parent {
            return values(node: parent) {
                node.environment?(&$0)
                transform(&$0)
            }
        }

        var values = EnvironmentValues()
        node.environment?(&values)
        transform(&values)
        return values
    }
}
