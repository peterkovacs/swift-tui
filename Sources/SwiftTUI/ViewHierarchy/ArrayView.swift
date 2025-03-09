struct ArrayView<Content: View & Sendable>: View, PrimitiveView {
    let content: [Content]

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = Node(view: self, parent: parent, root: root)

        for i in content {
            node.add(at: node.children.endIndex, node: i.view.build(parent: node, root: root))
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
