@MainActor protocol LayoutVisitor {
    static var axis: Axis { get }
    mutating func visit(node: Control, size: @escaping (Size) -> Size)
}

enum Axis: Sendable {
    case vertical
    case horizontal
}
