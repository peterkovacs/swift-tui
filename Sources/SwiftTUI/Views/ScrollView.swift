public struct ScrollView<Content: View>: View, PrimitiveView {
    let axes: LayoutAxis.Set
    let content: Content

    public init(_ axes: LayoutAxis.Set = [.vertical], @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = ScrollViewNode(
            view: self,
            parent: parent,
            axes: axes
        )

        node.add(at: 0, node: content.view.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let node = node as? ScrollViewNode else { fatalError() }

        node.axes = axes
        node.children[0].update(view: content.view)
        // TODO: Might need to do something to handle contentOffset changes.
    }
}

class ScrollViewNode: VStackNode {
    var axes: LayoutAxis.Set
    var contentOffset: Position = .init(column: 0, line: 0)
    var contentSize: Size = .zero

    init(view: any GenericView, parent: Node?, axes: LayoutAxis.Set) {
        self.axes = axes
        super.init(view: view, parent: parent, alignment: .center, spacing: 0)
    }

    override func layout(rect: Rect) -> Rect {
        let contentSize = layoutVisitor.layout(
            rect: .init(
                position: .zero,
                size: super.size(
                    proposedSize:  .init(
                        width: axes.contains(.horizontal) ? .infinity : rect.size.width,
                        height: axes.contains(.vertical) ? .infinity : rect.size.height
                    )
                )
            )
        ).size

        frame = .init(
            position: rect.position,
            size: .init(
                width: min(rect.size.width, contentSize.width),
                height: min(rect.size.height, contentSize.height)
            )
        )

//        // TODO: Verify This
//        if rect.size.height + contentOffset.line > contentSize.height {
//            contentOffset.line = contentSize.height - rect.size.height
//        }
//
//        if rect.size.width + contentOffset.column > contentSize.width {
//            contentOffset.column = contentSize.width - rect.size.width
//        }

        return frame
    }

    override func size(proposedSize: Size) -> Size {
        contentSize = super.size(
            proposedSize:  .init(
                width: axes.contains(.horizontal) ? .infinity : proposedSize.width,
                height: axes.contains(.vertical) ? .infinity : proposedSize.height
            )
        )

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
        super.description + " [offset:\(contentOffset) size:\(contentSize)]"
    }
}
