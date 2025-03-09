
extension View {
    /// Start an asynchronous Task when a view appears. This task is automatically cancelled when the view is removed.
    public func task(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        TaskView(id: nil as Int?, content: self, priority: priority, action: action)
    }

    public func task<T>(
        id value: T,
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View where T : Equatable {
        TaskView(id: value, content: self, priority: priority, action: action)
    }
}

struct TaskView<ID: Equatable, Content: View>: View, PrimitiveView {
    let id: ID?
    let content: Content
    let priority: TaskPriority
    let action: @Sendable () async -> Void

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = TaskNode(
            view: self.view,
            parent: parent,
            root: root,
            action: action,
            priority: priority,
            id: id
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        guard let node = node as? TaskNode<ID> else { fatalError("Unexpected node type") }

        node.view = self
        node.id = id
        node.priority = priority
        node.children[0].update(view: content.view)
    }
}

@globalActor
actor TaskActor {
    static let shared = TaskActor()
}

@MainActor
protocol Taskable {
    var task: Task<Void, Never>? { get }
}

final class TaskNode<ID: Equatable>: Node, Taskable {
    let action: @Sendable () async -> Void
    var priority: TaskPriority
    var task: Task<Void, Never>?
    var id: ID? {
        didSet {
            if oldValue != id {
                task?.cancel()
                task = nil

                // TODO: Find a better way to make the task start again.
                invalidateLayout()
            }
        }
    }

    init(
        view: any GenericView,
        parent: Node?,
        root: RootNode?,
        action: @escaping @Sendable () async -> Void,
        priority: TaskPriority,
        id: ID?
    ) {
        self.action = action
        self.priority = priority
        self.id = id

        super.init(view: view, parent: parent, root: root)
    }

    deinit {
        task?.cancel()
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        super.layout(visitor: &visitor)
        if task == nil {
            task = .init(priority: priority) { @TaskActor [action] in
                await action()
            }
        }
    }
}
