public enum LayoutAxis: EnvironmentKey, Sendable {
    case none
    case vertical
    case horizontal

    public static var defaultValue: Self { .vertical }
}

extension EnvironmentValues {
    public var layoutAxis: LayoutAxis {
        get { self[LayoutAxis.self] }
        set { self[LayoutAxis.self] = newValue }
    }
}
