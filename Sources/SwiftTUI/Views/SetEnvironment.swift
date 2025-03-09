public extension View {
    func environment<T>(_ keyPath: WritableKeyPath<EnvironmentValues, T>, _ value: T) -> some View {
        SetEnvironmentView(
            content: self,
            keyPath: keyPath,
            value: value
        )
    }
}

struct SetEnvironmentView<Content: View, EnvironmentValue>: View, PrimitiveView {
    let content: Content
    let keyPath: WritableKeyPath<EnvironmentValues, EnvironmentValue>
    let value: EnvironmentValue

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = Node(
            view: self.view,
            parent: parent,
            root: root
        )

        node.environment = { $0[keyPath: keyPath] = value }
        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        node.environment = { $0[keyPath: keyPath] = value }
        node.children[0].update(view: content.view)
    }
}
