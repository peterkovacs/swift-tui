
// TODO: Documentation on how to create an EnviornmentKey.
@MainActor public protocol EnvironmentKey {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}

public struct EnvironmentValues {
    var values: [ObjectIdentifier: any Sendable] = [:]
    @MainActor public subscript<K: EnvironmentKey>(key: K.Type) -> K.Value {
        get { values[ObjectIdentifier(key)] as? K.Value ?? K.defaultValue }
        set { values[ObjectIdentifier(key)] = newValue }
    }
}
