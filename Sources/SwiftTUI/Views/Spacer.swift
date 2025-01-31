public struct Spacer: View, PrimitiveView {
    @Environment(\.layoutAxis) var layoutAxis
    let minLength: Extended
    public init(minLength: Extended? = nil) {
        self.minLength = minLength ?? 0
    }

    func build(parent: Node?) -> Node {
        let node = SpacerNode(
            view: self,
            parent: parent,
            minLength: minLength,
            layoutAxis: _layoutAxis
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? SpacerNode else {
            fatalError("Invalid node type")
        }

        node.set(references: self)

        node.minLength = minLength
        node.layoutAxis = layoutAxis
    }
}

class SpacerNode: DynamicPropertyNode, Control {
    var minLength: Extended
    var layoutAxis: LayoutAxis

    init(view: Spacer, parent: Node?, minLength: Extended, layoutAxis: Environment<LayoutAxis>) {
        self.minLength = minLength
        self.layoutAxis = .defaultValue
        super.init(view: view, parent: parent, content: view)
        self.layoutAxis = layoutAxis.wrappedValue
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: sizeElement)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(layout: layoutElement)
    }

    override func layout(rect: Rect) -> Rect {
        switch layoutAxis {
        case .none:
            return super.layout(rect: .zero)
        case .horizontal:
            return super.layout(
                rect: .init(
                    position: rect.position,
                    size: .init(
                        width: rect.size.width < minLength ? minLength : rect.size.width,
                        height: rect.size.height
                    )
                )
            )
        case .vertical:
            return super.layout(
                rect: .init(
                    position: rect.position,
                    size: .init(
                        width: rect.size.width,
                        height: rect.size.height < minLength ? minLength : rect.size.height
                    )
                )
            )
        }

    }

    func size(proposedSize: Size) -> Size {
        switch layoutAxis {
        case .none: return .zero
        case .horizontal:
            return .init(width: proposedSize.width < minLength ? minLength : proposedSize.width, height: 0)
        case .vertical:
            return .init(width: 0, height: proposedSize.height < minLength ? minLength : proposedSize.height)
        }
    }
}
