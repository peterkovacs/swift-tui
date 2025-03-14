import Observation

struct ComposedView<Content: View>: GenericView {
    let view: Content

    func build(parent: Node?, root: RootNode?) -> Node {
        // TODO: State & Environment Properties

        let node = DynamicPropertyNode(view: self, parent: parent, root: root, content: view)

        let child = withObservationTracking {
            view.body.view.build(parent: node, root: root)
        } onChange: {
            MainActor.assumeIsolated { node.invalidate() }
        }

        node.add(at: 0, node: child)
        return node
    }

    func update(node: Node) {
        guard let node = node as? DynamicPropertyNode else { fatalError() }

        node.view = self
        node.set(references: view)

        withObservationTracking {
            node.children[0].update(view: view.body.view)
        } onChange: {
            MainActor.assumeIsolated { node.invalidate() }
        }
    }
}
