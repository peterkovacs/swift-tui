extension View {
    public func onAppear(perform action: @escaping @MainActor () -> Void) -> some View {
        AppearanceModifier(content: self, onAppear: action, onDisappear: nil)
    }

    public func onDisappear(perform action: @escaping @MainActor () -> Void) -> some View {
        AppearanceModifier(content: self, onAppear: nil, onDisappear: action)
    }
}

struct AppearanceModifier<Content: View>: View, PrimitiveView {
    let content: Content
    let onAppear: (@MainActor () -> Void)?
    let onDisappear: (@MainActor () -> Void)?

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = AppearanceNode(
            view: self.view,
            parent: parent,
            root: root,
            onAppear: onAppear,
            onDisappear: onDisappear
        )
        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        guard let node = node as? AppearanceNode else { fatalError() }
        node.onDisappear = onDisappear
        node.children[0].update(view: content.view)
    }
}

final class AppearanceNode: Node {
    var onDisappear: (@MainActor () -> Void)?

    init(
        view: any GenericView,
        parent: Node?,
        root: RootNode?,
        onAppear: (@MainActor () -> Void)?,
        onDisappear: (@MainActor () -> Void)?
    ) {
        self.onDisappear = onDisappear
        super.init(view: view, parent: parent, root: root)
        onAppear?()
    }

    deinit {
        let action = onDisappear
        MainActor.assumeIsolated { action?() }
    }
}
