public enum LayoutAxis: EnvironmentKey, Sendable {
    case none
    case vertical
    case horizontal

    public static var defaultValue: Self { .vertical }

    public struct Set: OptionSet, RawRepresentable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let vertical: Set = .init(rawValue: 1 << 0)
        public static let horizontal: Set = .init(rawValue: 1 << 1)
    }
}

extension EnvironmentValues {
    public var layoutAxis: LayoutAxis {
        get { self[LayoutAxis.self] }
        set { self[LayoutAxis.self] = newValue }
    }
}
