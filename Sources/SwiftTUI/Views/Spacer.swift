public struct Spacer: View, PrimitiveView {
    let minLength: Extended
    public init(minLength: Extended? = nil) {
        self.minLength = minLength ?? 0
    }

    func build(parent: Node?) -> Node {
        let node = SpacerNode(
            view: self,
            parent: parent,
            minLength: minLength
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? SpacerNode else {
            fatalError("Invalid node type")
        }

        node.minLength = minLength
    }
}

class SpacerNode: Node, Control {
    var minLength: Extended

    init(view: any GenericView, parent: Node?, minLength: Extended) {
        self.minLength = minLength
        super.init(view: view, parent: parent)
    }

    override func size<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self) { [self] proposedSize in
            switch T.axis {
            case .horizontal:
                return .init(width: proposedSize.width < minLength ? minLength : proposedSize.width, height: 0)
            case .vertical:
                return .init(width: 0, height: proposedSize.height < minLength ? minLength : proposedSize.height)
            }
        }
    }

    override func layout<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self) { [self] size in
            switch T.axis {
            case .horizontal:
                self.layout(size: .init(width: size.width < minLength ? minLength : size.width, height: size.height))
            case .vertical:
                self.layout(size: .init(width: size.width, height: size.height < minLength ? minLength : size.height))
            }

        }
    }

    override func move(to position: Position) {
        super.move(to: position)
    }

    // This method is only called by {horizontal,vertical}Flexibility, so we'll just return back the proposed size since this is infinitely flexible.
    func size(proposedSize: Size) -> Size {
        proposedSize
    }
}
