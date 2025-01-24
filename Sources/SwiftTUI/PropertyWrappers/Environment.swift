import Foundation

@propertyWrapper
public struct Environment<Wrapped: Sendable>: EnvironmentValue, Sendable {
    var reference: EnvironmentReference<Wrapped>

    public init(_ keyPath: KeyPath<EnvironmentValues, Wrapped> & Sendable) {
        self.reference = .init(keyPath: keyPath)
    }

    public var wrappedValue: Wrapped {
        get { reference.wrappedValue }
    }

    @MainActor func setup(node: Node) {
        reference.node = node
    }
}

protocol EnvironmentValue: Sendable {
    associatedtype Wrapped: Sendable
    @MainActor var wrappedValue: Wrapped { get }
    @MainActor func setup(node: Node)
}

final class EnvironmentReference<Wrapped>: Sendable  {
    private let keyPath: KeyPath<EnvironmentValues, Wrapped> & Sendable
    init(keyPath: KeyPath<EnvironmentValues, Wrapped> & Sendable) {
        self.keyPath = keyPath
    }

    @MainActor weak var node: Node?
    @MainActor var wrappedValue: Wrapped {
        guard let node else { fatalError("Accessed Environment prior to initialization") }
        let values = values(node: node) { _ in }
        return values[keyPath: keyPath]
    }

    @MainActor private func values(
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
