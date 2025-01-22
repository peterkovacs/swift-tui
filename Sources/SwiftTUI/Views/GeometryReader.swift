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

        node.add(at: 0, node: content(node.frame.size.clamped(to: .zero)).view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? GeometryReaderNode else { fatalError() }

        node.view = self
        node.children[0].update(view: content(node.frame.size.clamped(to: .zero)).view)
    }
}

class GeometryReaderNode: ZStackNode {
    init(view: any GenericView, parent: Node?) {
        super.init(view: view, parent: parent, alignment: .topLeading)
    }

    override var frame: Rect {
        didSet {
            if oldValue != frame { invalidate() }
        }
    }

    override func size(proposedSize: Size) -> Size {
        return proposedSize
    }

    override func layout(rect: Rect) -> Rect {
        super.layout(
            rect: layoutVisitor.layout(
                rect: rect
            )
        )
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(
            size: .init(node: self) { proposedSize in
                proposedSize
            }
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self) { rect in
                self.layoutVisitor.layout(rect: rect)
                return rect
            } frame: {
                self.frame = $0
                return $0
            } global: {
                self.global
            }
        )
    }
}
