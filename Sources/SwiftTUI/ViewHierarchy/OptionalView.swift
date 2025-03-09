public struct OptionalView<Wrapped: View>: View, PrimitiveView, GenericView {
    let content: Wrapped?

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = Node(view: self, parent: parent, root: root)

        if let content {
            node.add(at: 0, node: content.view.build(parent: node, root: root))
        }

        return node
    }

    func update(node: Node) {
        let last = node.view as! Self
        node.view = self
        switch (last.content, content) {
        case (.none, .none):
            break
        case (.none, .some(let newValue)):
            node.add(at: 0, node: newValue.view.build(parent: node, root: node.root))
            node.invalidateLayout()
        case (.some, .none):
            node.remove(at: 0)
            node.invalidateLayout()
        case (.some, .some(let newValue)):
            node.children[0].update(view: newValue.view)
            node.invalidateLayout()
        }
    }
}
