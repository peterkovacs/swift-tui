
public enum HorizontalAlignment: Sendable, Hashable {
    case leading
    case center
    case trailing
}

public struct VStack<Content: View>: View, PrimitiveView {
    let alignment: HorizontalAlignment
    let spacing: Extended
    let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Extended = 0,
        @ViewBuilder _ content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = VStackNode(
            view: self.view,
            parent: parent,
            alignment: alignment,
            spacing: spacing
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? VStackNode else { fatalError() }
        node.view = self
        node.children[0].update(view: content.view)
        node.alignment = alignment
        node.spacing = spacing
        node._visitor = nil
    }
}

class VStackNode: Node, Control {
    var alignment: HorizontalAlignment
    var spacing: Extended

    fileprivate var _visitor: VerticallyProportionalVisitor? = nil
    var visitor: VerticallyProportionalVisitor {
        let visitor = _visitor ?? VerticallyProportionalVisitor(spacing: spacing, children: children)
        _visitor = visitor
        return visitor
    }

    init(
        view: any GenericView,
        parent: Node?,
        alignment: HorizontalAlignment,
        spacing: Extended
    ) {
        self.alignment = alignment
        self.spacing = spacing
        super.init(view: view, parent: parent)
    }

    struct VerticallyProportionalVisitor: SizeVisitor {
        let spacing: Extended
        var visited: [(node: Control, size: ProposedSize)]

        fileprivate init(spacing: Extended, children: [Node]) {
            self.spacing = spacing
            self.visited = []
            for child in children {
                child.size(visitor: &self)
            }
        }

        static var axis: Axis { .vertical }

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }

        func size(proposedSize: Size) -> Size {
            let children = visited
                .map { (size: $0.size, flexibility: $0.node.verticalFlexibility(width: proposedSize.width)) }
                .sorted { $0.flexibility < $1.flexibility }

            // Anything that is infinitely flexible does not get spacing before it
            var resultSize: Size = .init(
                width: 0,
                height: Extended(children.filter { $0.flexibility != .infinity }.count - 1) * spacing
            )

            var remaining = children.count

            for (size, _) in children {
                // How much height is remaining based on what's used so far.
                let remainingHeight = resultSize.height == .infinity ? .infinity : proposedSize.height - resultSize.height

                // How much does this child use.
                let childSize = size(
                    Size(
                        width: proposedSize.width,
                        height: remainingHeight / Extended(remaining)
                    )
                )

                resultSize.height += childSize.height
                resultSize.width = max(resultSize.width, childSize.width)
                remaining -= 1
            }

            return resultSize
        }
    }

    override func size<T>(visitor: inout T) where T : SizeVisitor {
        visitor.visit(node: self, size: self.visitor.size(proposedSize:))
    }

    func size(proposedSize: Size) -> Size {
        self.visitor.size(proposedSize: proposedSize)
    }

}
