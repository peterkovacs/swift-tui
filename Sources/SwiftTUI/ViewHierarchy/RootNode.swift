///
/// A RootNode represents the implicit VStack at the root of a view hierarchy.
/// There are two places where root nodes are used -- the actual top-level root, and the top-level of any ScrollView.
///
@MainActor class RootNode: VStackNode {
    private(set) var application: Application?
    private(set) var focusManager: FocusManager!

    override var root: RootNode? { self }

    init<T: View>(root view: T, application: Application?) {
        self.application = application
        super.init(root: VStack { view })

        add(at: 0, node: view.view.build(parent: self))
        self.focusManager = .init(root: self)
    }

    init<T: View>(view: T, parent: Node?) {
        self.application = parent?.root?.application
        super.init(view: VStack { view }, parent: parent, alignment: .center, spacing: 0)

        let child = view.view.build(parent: self)
        add(at: 0, node: child)
        self.focusManager = .init(secondary: child)
    }

    func invalidate(node: Node, frame: @escaping (Node) -> Rect = \.global) {
        application?.invalidate(node: node, frame: frame)
    }

    override func update(view: any GenericView) {
        super.update(view: view)
        focusManager?.evaluate(focus: self)
    }
}
