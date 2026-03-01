extension View {
    public func onMouseMove( _ action: @escaping (Position) -> Void) -> some View {
        OnMouseMove(onMouseMove: action, content: self)
    }
}

struct OnMouseMove<Content: View>: View, PrimitiveView {
    let content: Content
    let onMouseMove: (Position) -> Void

    public init(onMouseMove: @escaping (Position) -> Void, content: Content) {
        self.content = content
        self.onMouseMove = onMouseMove
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = OnMouseMoveNode(
            view: self.view,
            parent: parent,
            root: root,
            callback: onMouseMove,
            content: content
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node

    }


    func update(node: Node) {
        guard let node = node as? OnMouseMoveNode else { fatalError() }
        node.callback = onMouseMove
        node.children[0].update(view: content.view)
    }


}

class OnMouseMoveNode: VStackNode {
    var callback: (Position) -> Void

    init<Content: View>(
        view: any GenericView,
        parent: Node?,
        root: RootNode?,
        callback: @escaping (Position) -> Void,
        content: Content
    ) {
        self.callback = callback
        super.init(view: view, parent: parent, root: root, alignment: .center, spacing: 0)
    }

    override func hitTest(at position: Position, key: Key) -> (any Control)? {
        guard let control = super.hitTest(at: position, key: key) else { return nil }

        if case .mouseMove(let position) = key.key {
            self.callback(position)
        }

        return control
    }
}
