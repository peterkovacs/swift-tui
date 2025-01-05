public struct ConditionalView<TrueContent: View, FalseContent: View>: View, PrimitiveView {
    enum Content {
        case a(TrueContent)
        case b(FalseContent)
    }

    let content: Content

    func build(parent: Node?) -> Node {
        let node = Node(view: self, parent: parent)
        switch content {
        case .a(let value):
            node.add(at: 0, node: value.view.build(parent: node))
        case .b(let value):
            node.add(at: 0, node: value.view.build(parent: node))
        }

        return node
    }

    func update(node: Node) {
        let last = node.view as! Self
        node.view = self
        switch (last.content, self.content) {
        case (.a, .a(let newValue)):
            node.children[0].update(view: newValue.view)
        case (.b, .b(let newValue)):
            node.children[0].update(view: newValue.view)
        case (.b, .a(let newValue)):
            node.remove(at: 0)
            node.add(at: 0, node: newValue.view.build(parent: node))
        case (.a, .b(let newValue)):
            node.remove(at: 0)
            node.add(at: 0, node: newValue.view.build(parent: node))
        }
    }
}
