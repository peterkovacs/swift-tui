
public enum VerticalAlignment: Sendable, Hashable {
    case top
    case center
    case bottom
}

public struct HStack<Content: View>: View, PrimitiveView {
    let alignment: VerticalAlignment
    let spacing: Extended
    let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: Extended = 1,
        @ViewBuilder _ content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = HStackNode(
            view: self.view,
            parent: parent,
            alignment: alignment,
            spacing: spacing
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? HStackNode else { fatalError() }
        node.view = self
        node.children[0].update(view: content.view)
        node.alignment = alignment
        node.spacing = spacing
    }
}

class HStackNode: Node, Control {
    var alignment: VerticalAlignment
    var spacing: Extended

    init(
        view: any GenericView,
        parent: Node?,
        alignment: VerticalAlignment,
        spacing: Extended
    ) {
        self.alignment = alignment
        self.spacing = spacing
        super.init(view: view, parent: parent)
    }

    struct HorizontallyProportionalVisitor: SizeVisitor {
        let spacing: Extended
        var visited: [(node: Control, size: ProposedSize)]

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }

        func size(proposedSize: Size) -> Size {
            var resultSize: Size = .zero
            var remaining = visited.count
            let children = visited.sorted {
                $0.node.verticalFlexibility(width: proposedSize.width) < $1.node.verticalFlexibility(width: proposedSize.width)
            }

            for (_, size) in children {
                // How much height is remaining based on what's used so far.
                let remainingWidth = resultSize.width == .infinity ? .infinity : proposedSize.width - resultSize.width

                // How much does this child use.
                let childSize = size(
                    Size(
                        width: remainingWidth / Extended(remaining),
                        height: proposedSize.height
                    )
                )

                resultSize.height = max(resultSize.height, childSize.height)
                resultSize.width += childSize.width

                if remaining > 1 {
                    resultSize.width += spacing
                }

                remaining -= 1
            }

            return resultSize
        }
    }

    override func size<T>(visitor: inout T) where T : SizeVisitor {
        var myVisitor = HorizontallyProportionalVisitor(spacing: spacing, visited: [])

        for child in children {
            child.size(visitor: &myVisitor)
        }

        visitor.visit(node: self, size: myVisitor.size(proposedSize:))
    }

    func size(proposedSize: Size) -> Size {
        var visitor = HorizontallyProportionalVisitor(spacing: spacing, visited: [])
        size(visitor: &visitor)
        return visitor.size(proposedSize: proposedSize)
    }

}
