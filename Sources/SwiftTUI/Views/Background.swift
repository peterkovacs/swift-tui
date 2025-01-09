extension View {
    public func background(_ color: Color) -> some View {
        Background(color: color, content: self)
    }
}

struct Background<Content: View>: View, PrimitiveView {
    let color: Color
    let content: Content

    func build(parent: Node?) -> Node {
        let node = BackgroundNode(
            view: self,
            parent: parent,
            color: color
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? BackgroundNode else { fatalError() }
        node.color = color
    }
}

final class BackgroundNode: Node {
    var color: Color = .default

    init(
        view: any GenericView,
        parent: Node?,
        color: Color
    ) {
        self.color = color
        super.init(view: view, parent: parent)
    }

    override func draw(
        rect: Rect,
        into window: inout CellGrid<Cell?>
    ) {
        draw(rect: rect) { rect, node in

            for i in rect.indices {
                window[i, default: .init(char: " ")].backgroundColor = color
            }
        }

        super.draw(rect: rect, into: &window)
    }
}
