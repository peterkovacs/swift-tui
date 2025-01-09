@MainActor protocol LayoutVisitor {
    mutating func visit(node: Control, size: @escaping (Size) -> Size)
}
