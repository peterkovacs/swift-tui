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
    var minLength: Extended { didSet { if minLength != oldValue { invalidateLayout() } } }
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

    func layout(rect: Rect) -> Rect {
        frame = .init(
            position: rect.position,
            size: size(proposedSize: rect.size).clamped(to: .zero)
        )

        return frame
    }

    func size(proposedSize: Size) -> Size {
        switch layoutAxis {
        case .none: return .zero
        case .horizontal:
            return .init(width: proposedSize.width < minLength ? minLength : proposedSize.width, height: 1)
        case .vertical:
            return .init(width: 1, height: proposedSize.height < minLength ? minLength : proposedSize.height)
        }
    }
}
