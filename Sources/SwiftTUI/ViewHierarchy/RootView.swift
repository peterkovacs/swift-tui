struct RootView<Content: View>: View, GenericView {
    let content: Content

    var body: Never { fatalError() }

    func build(parent: Node?) -> Node {
        content.view.build(parent: parent)
    }

    func update(node: Node) {
        node.update(view: content.view)
    }
}
