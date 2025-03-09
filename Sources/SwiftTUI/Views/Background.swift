extension View {
    public func background(_ color: Color) -> some View {
        Background(color: color, content: self)
    }
}

struct Background<Content: View>: View, PrimitiveView {
    let color: Color
    let content: Content

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = BackgroundNode(
            view: self,
            parent: parent,
            root: root,
            content: self,
            color: color
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        guard let node = node as? BackgroundNode else { fatalError() }
        node.color = color

        node.children[0].update(view: content.view)
    }
}

final class BackgroundNode: ModifierNode {
    var color: Color = .default

    init<Content: View>(
        view: any GenericView,
        parent: Node?,
        root: RootNode?,
        content: Content,
        color: Color
    ) {
        self.color = color
        super.init(view: view, parent: parent, root: root, content: content)
    }

    override func draw(rect: Rect, action: (Rect, any Control, Rect) -> Void) {
        for element in layoutVisitor.visited {
            let frame = element.global()
            guard let invalidated = frame.intersection(rect) else { continue }

            action(invalidated, element.node, frame)
        }
    }

    override func draw(
        rect: Rect,
        into window: inout Window<Cell?>
    ) {
        draw(rect: rect) { invalidated, node, frame in
            for i in frame.indices {
                window[i, default: .init(char: " ")].backgroundColor = color
            }
        }

        super.draw(rect: rect, into: &window)
    }
}
