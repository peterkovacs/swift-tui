public struct Spacer: View, PrimitiveView {
    @Environment(\.layoutAxis) var layoutAxis
    let minLength: Extended
    public init(minLength: Extended? = nil) {
        self.minLength = minLength ?? 0
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = SpacerNode(
            view: self,
            parent: parent,
            root: root,
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

    init(view: Spacer, parent: Node?, root: RootNode?, minLength: Extended, layoutAxis: Environment<LayoutAxis>) {
        self.minLength = minLength
        self.layoutAxis = .defaultValue
        super.init(view: view, parent: parent, root: root, content: view)
        self.layoutAxis = layoutAxis.wrappedValue
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(
            size: .init(node: self) { [weak self] proposedSize in
                self?.size(proposedSize: proposedSize) ?? .zero
            } horizontalFlexibility: { [weak self] height in
                self?.layoutAxis == .horizontal ? .infinity : 0
            } verticalFlexibility: { [weak self] width in
                self?.layoutAxis == .vertical ? .infinity : 0
            }

        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(
                node: self
            ) { [weak self] rect in
                self?.layout(rect: rect) ?? .zero
            } adjust: { [weak self] position in
                self?.frame.position += position
            } global: { [weak self] in
                self?.global ?? .zero
            } horizontalFlexibility: { [weak self] height in
                self?.layoutAxis == .horizontal ? .infinity : 0
            } verticalFlexibility: { [weak self] width in
                self?.layoutAxis == .vertical ? .infinity : 0
            }
        )
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
            return .init(
                width: proposedSize.width == .infinity
                ? minLength
                : ( proposedSize.width < minLength
                    ? minLength
                    : proposedSize.width ),
                height: 1
            )
        case .vertical:
            return .init(
                width: 1,
                height: proposedSize.height == .infinity
                ? minLength
                : ( proposedSize.height < minLength
                    ? minLength
                    : proposedSize.height )
            )
        }
    }
}
