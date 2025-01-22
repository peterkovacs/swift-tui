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

class SpacerNode: ComposedNode, Control {
    var minLength: Extended
    var layoutAxis: LayoutAxis

    init(view: Spacer, parent: Node?, minLength: Extended, layoutAxis: Environment<LayoutAxis>) {
        self.minLength = minLength
        self.layoutAxis = .defaultValue
        super.init(view: view, parent: parent, content: view)
        self.layoutAxis = layoutAxis.wrappedValue
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(
            size: .init(node: self) { [weak self] proposedSize in
                guard let self else { return .zero }
                switch layoutAxis {
                case .none: return .zero
                case .horizontal:
                    return .init(width: proposedSize.width < minLength ? minLength : proposedSize.width, height: 0)
                case .vertical:
                    return .init(width: 0, height: proposedSize.height < minLength ? minLength : proposedSize.height)
                }
            }
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self) { [weak self] rect in
                guard let self else { return .zero }
                switch layoutAxis {
                case .none:
                    return self.layout(rect: .zero)
                case .horizontal:
                    return self.layout(
                        rect: .init(
                            position: rect.position,
                            size: .init(
                                width: rect.size.width < minLength ? minLength : rect.size.width,
                                height: rect.size.height
                            )
                        )
                    )
                case .vertical:
                    return self.layout(
                        rect: .init(
                            position: rect.position,
                            size: .init(
                                width: rect.size.width,
                                height: rect.size.height < minLength ? minLength : rect.size.height
                            )
                        )
                    )
                }

            } frame: { [weak self] rect in
                self?.frame = rect
                return rect
            } global: { [weak self] in
                self?.global ?? .zero
            }
        )
    }

    // This method is only called by {horizontal,vertical}Flexibility, so we'll just return back the proposed size since this is infinitely flexible.
    func size(proposedSize: Size) -> Size {
        proposedSize
    }
}
