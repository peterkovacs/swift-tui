@frozen
public struct Group<Content: View>: View, PrimitiveView {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = Node(
            view: self,
            parent: parent,
            root: root
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        node.children[0].update(view: content.view)
    }
}
