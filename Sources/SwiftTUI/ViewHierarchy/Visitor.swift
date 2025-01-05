@MainActor protocol SizeVisitor {
    typealias ProposedSize = (Size) -> Size
    mutating func visit(node: Control, size: @escaping ProposedSize)
    static var axis: Axis { get }
}

enum Axis {
    case vertical
    case horizontal
}

struct Visitor: SizeVisitor {
    var size: ProposedSize = { _ in .zero }
    static var axis: Axis { .vertical }

    mutating func visit(node: any Control, size: @escaping ProposedSize) {
        self.size = size
    }
}
