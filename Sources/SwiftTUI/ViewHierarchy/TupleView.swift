
struct TupleView<each C: View & Sendable>: View, PrimitiveView {
    let content: (repeat (each C))

    func build(parent: Node?) -> Node {
        let node = Node(view: self, parent: parent)

        var index = 0
        for c in repeat (each content) {
            node.add(at: index, node: c.view.build(parent: node))
            index += 1
        }
        
        return node
    }

    func update(node: Node) {
        node.view = self

        var index = 0
        for c in repeat (each content) {
            node.children[index].update(view: c.view)
            index += 1
        }
    }
}
