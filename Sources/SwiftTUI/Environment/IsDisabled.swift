public extension View {
    func disabled(_ isDisabled: Bool = true) -> some View {
        environment(\.isDisabled, isDisabled)
    }
}

private struct IsDisabledKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var isDisabled: Bool {
        get { self[IsDisabledKey.self] }
        set { self[IsDisabledKey.self] = newValue }
    }
}
