/// An interface for a stored variable that updates an external property of a view.
///
/// The view gives values to these properties prior to recomputing the view's ``View/body-swift.property``.
@MainActor protocol DynamicProperty {
    func setup(node: DynamicPropertyNode, label: String)
}

class DynamicPropertyNode: Node {
    var state: [AnyHashable: Any] = [:]

    init<Content: View>(view: any GenericView, parent: Node?, content: Content) {
        super.init(view: view, parent: parent)
        set(references: content)
    }

    func set<Wrapped>(state: AnyHashable, value: Wrapped) {
        self.state[state] = value
        self.invalidate()
    }

    func get<Wrapped>(state: AnyHashable) -> Wrapped? {
        self.state[state] as? Wrapped
    }

    func set<Content: View>(references content: Content) {
        // Set the stateValue references to this node in any contained @State or @Environment properties.
        for (label, value) in Mirror(reflecting: content).children {
            guard let label else { continue }
            switch value {
            case let value as any DynamicProperty:
                value.setup(node: self, label: label)
            default:
                break
            }
        }
    }
}
