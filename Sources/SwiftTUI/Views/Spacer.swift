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

    override func size<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self) { [self] proposedSize in
            switch layoutAxis {
            case .horizontal:
                return .init(width: proposedSize.width < minLength ? minLength : proposedSize.width, height: 0)
            case .vertical:
                return .init(width: 0, height: proposedSize.height < minLength ? minLength : proposedSize.height)
            }
        }
    }

    override func layout<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self) { [self] size in
            switch layoutAxis {
            case .horizontal:
                self.layout(size: .init(width: size.width < minLength ? minLength : size.width, height: size.height))
            case .vertical:
                self.layout(size: .init(width: size.width, height: size.height < minLength ? minLength : size.height))
            }

        }
    }

    // This method is only called by {horizontal,vertical}Flexibility, so we'll just return back the proposed size since this is infinitely flexible.
    func size(proposedSize: Size) -> Size {
        proposedSize
    }
}
