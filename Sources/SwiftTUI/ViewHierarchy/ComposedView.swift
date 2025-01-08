import Observation

struct ComposedView<Content: View>: GenericView {
    let view: Content

    func build(parent: Node?) -> Node {
        // TODO: State & Environment Properties

        let node = ComposedNode(view: self, parent: parent, content: view)

        let child = withObservationTracking {
            view.body.view.build(parent: node)
        } onChange: {
            MainActor.assumeIsolated { node.invalidate() }
        }

        node.add(at: 0, node: child)
        return node
    }

    func update(node: Node) {
        node.view = self

        withObservationTracking {
            node.children[0].update(view: view.body.view)
        } onChange: {
            MainActor.assumeIsolated { node.invalidate() }
        }
    }
}

class ComposedNode: Node {
    var state: [String: Any] = [:]

    init<Content: View>(view: any GenericView, parent: Node?, content: Content) {
        state = [:]
        super.init(view: view, parent: parent)

        // Set the stateValue references to this node in any contained @State properties.
        for (label, value) in Mirror(reflecting: content).children {
            if let stateValue = value as? any StateValue, let label {
                stateValue.setup(node: self, label: label)
            }
        }
    }
}
