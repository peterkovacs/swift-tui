public struct ScrollView<Content: View>: View, PrimitiveView {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = ScrollViewNode(
            view: self,
            parent: parent
        )

        node.add(at: 0, node: VStack { content }.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let node = node as? ScrollViewNode else { fatalError() }

        node.children[0].update(view: VStack { content }.view)
        // TODO: Might need to do something to handle contentOffset changes.
    }
}

class ScrollViewNode: Node, Control {
    var contentOffset: Position = .init(column: 0, line: 0)
    var contentSize: Size = .zero

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: sizeElement)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(layout: layoutElement)
    }

    override func layout(rect: Rect) -> Rect {
        super.layout(
            rect: .init(
                position: rect.position,
                size: self.size(proposedSize: rect.size)
            )
        )
    }

    func size(proposedSize: Size) -> Size {
        guard let vstack = children[0] as? VStackNode else { fatalError() }
        contentSize = vstack.size(proposedSize: .init(width: .infinity, height: .infinity))

        // TODO: Handle Scrollbars.
        return .init(
            width: min(contentSize.width, proposedSize.width),
            height: min(contentSize.height, proposedSize.height)
        )
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        window.with(offset: -contentOffset) { window in
            children[0].draw(rect: rect + contentOffset, into: &window)
        }

        // TODO: Scrollbar
    }

    override var description: String {
        super.description + " [\(contentOffset) \(contentSize)"
    }
}
