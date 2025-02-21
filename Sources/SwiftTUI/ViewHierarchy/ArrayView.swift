
struct ArrayView<Content: View & Sendable>: View, PrimitiveView {
    let content: [Content]

    func build(parent: Node?) -> Node {
        let node = Node(view: self, parent: parent)

        for i in content {
            node.add(at: node.children.endIndex, node: i.view.build(parent: node))
        }

        return node
    }

    func update(node: Node) {
        node.view = self

        for (i, child) in content.enumerated() {
            node.children[i].update(view: child.view)
        }
    }
}
