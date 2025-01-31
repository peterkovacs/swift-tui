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

        node.add(at: 0, node: ZStack(alignment: .topLeading) { content(node.frame.size.clamped(to: .zero)) }.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? GeometryReaderNode else { fatalError() }

        node.view = self
        node.children[0].update(view: ZStack(alignment: .topLeading) { content(node.frame.size.clamped(to: .zero)) }.view)
    }
}

final class GeometryReaderNode: Node, Control {
    typealias SizeVisitor = ZStackNode.SizeVisitor
    typealias LayoutVisitor = ZStackNode.LayoutVisitor

    fileprivate var _sizeVisitor: SizeVisitor? = nil
    var sizeVisitor: SizeVisitor {
        let visitor = _sizeVisitor ?? SizeVisitor(children: children)
        _sizeVisitor = visitor
        return visitor
    }

    fileprivate var _layoutVisitor: LayoutVisitor? = nil
    var layoutVisitor: LayoutVisitor {
        get {
            let visitor = _layoutVisitor ?? LayoutVisitor(
                alignment: .topLeading,
                children: children
            )
            _layoutVisitor = visitor
            return visitor
        }
        set {
            _layoutVisitor = newValue
        }
    }

    override init(view: any GenericView, parent: Node?) {
        super.init(view: view, parent: parent)
        self.environment = { $0.layoutAxis = .none }
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

    func size(proposedSize: Size) -> Size {
        proposedSize.expanding(to: sizeVisitor.size(proposedSize: proposedSize))
    }

    override func layout(rect: Rect) -> Rect {

        super.layout(
            rect: layoutVisitor.layout(
                rect: .init(
                    position: rect.position,
                    size: sizeVisitor.size(proposedSize: rect.size)
                )
            )
            .union(rect)
        )
    }
}
