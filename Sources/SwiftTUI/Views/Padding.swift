extension View {
    public func padding(_ edges: Edges = .all, _ size: Extended = 1) -> some View {
        Padding(size: size, edges: edges, content: self)
    }
}

struct Padding<Content: View>: View, PrimitiveView {
    var size: Extended
    var edges: Edges
    let content: Content

    func build(parent: Node?) -> Node {
        let node = PaddingNode(
            view: self,
            parent: parent,
            content: self,
            size: size,
            edges: edges
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? PaddingNode else { fatalError() }

        node.view = self
        node.set(references: self)
        node.size = size
        node.edges = edges

        node.children[0].update(view: content.view)
    }
}

class PaddingNode: ModifierNode {
    var size: Extended { didSet { invalidateLayout() } }
    var edges: Edges { didSet { invalidateLayout() } }

    var paddingSize: Size {
        Size(
            width: (edges.contains(.left) ? size : 0) + (edges.contains(.right) ? size : 0),
            height: (edges.contains(.top) ? size : 0) + (edges.contains(.bottom) ? size : 0)
        )
    }

    var paddingPosition: Position {
        .init(
            column: edges.contains(.left) ? size : 0,
            line: edges.contains(.top) ? size : 0
        )
    }

    init<Content: View>(view: any GenericView, parent: Node?, content: Content, size: Extended, edges: Edges) {
        self.size = size
        self.edges = edges
        super.init(view: view, parent: parent, content: content)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        for element in layoutVisitor.visited {
            visitor.visit(
                layout: .init(
                    node: element.node
                ) { [paddingPosition, paddingSize] (rect: Rect) in
                    element.layout(rect + paddingPosition - paddingSize) - paddingPosition + paddingSize
                } adjust: { position in
                    element.adjust(position)
                } global: { [paddingPosition, paddingSize] in
                    element.global() - paddingPosition + paddingSize
                }
            )
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        for element in sizeVisitor.visited {
            visitor.visit(
                size: .init(node: element.node) { [paddingSize] (size: Size) in
                    element.size(size - paddingSize) + paddingSize
                }
            )
        }
    }

    override func draw(rect: Rect, action: (Rect, Control, Rect) -> Void) {
        // When called by node higher in the hierarchy, we want to draw any children, while adjusting their size
        // This can take the place of the standard draw method which accomplishes the same thing.
        for element in layoutVisitor.visited {
            // node.global is the position of the node, but doesn't allow any descendant Modifiers like ourselves to modify the frame.
            //
            let frame = element.global() - paddingPosition + paddingSize
            guard
                let invalidated = frame.intersection(rect)
            else { continue }

            action(invalidated, element.node, frame)
        }
    }

    override var description: String {
        return "Padding:\(layoutVisitor.visited.map { $0.global() - paddingPosition + paddingSize })"
    }
}
