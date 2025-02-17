import Observation

struct GeometryReader<Content: View>: View, PrimitiveView {
    let content: (Size) -> Content

    public init(@ViewBuilder content: @escaping (Size) -> Content) {
        self.content = content
    }

    func build(parent: Node?) -> Node {
        let node = GeometryReaderNode(
            view: view,
            parent: parent
        )

        let frame = node.frame.size.clamped(to: .zero)

        node.add(
            at: 0,
            node: content(frame).view.build(parent: node)
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? GeometryReaderNode else { fatalError() }

        let frame = node.frame.size.clamped(to: .zero)

        node.view = self
        node.children[0].update(view: content(frame).view)
    }
}

final class GeometryReaderNode: ZStackNode {

    init(view: any GenericView, parent: Node?) {
        super.init(view: view, parent: parent, alignment: .topLeading)
    }

    override var frame: Rect {
        didSet {
            if oldValue.size != frame.size {
                invalidate()
            }
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: sizeElement)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(layout: layoutElement)
    }

    override func size(proposedSize: Size) -> Size {
        proposedSize.expanding(to: sizeVisitor.size(proposedSize: proposedSize))
    }

    override func layout(rect: Rect) -> Rect {
        frame = layoutVisitor.layout(
            rect: .init(
                position: rect.position,
                size: sizeVisitor.size(proposedSize: rect.size)
            )
        )
        .union(rect)

        return frame
    }
}
