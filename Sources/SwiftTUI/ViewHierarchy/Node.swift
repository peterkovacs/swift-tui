
@MainActor
internal class Node {
    var view: any GenericView

    private(set) var application: Application?
    private(set) weak var parent: Node? = nil
    private(set) var children: [Node] = []

    /// Manipulation of this EnvironmentValues passing through this level.
    var environment: ((inout EnvironmentValues) -> Void)?

    /// Frame of this node, if it is a control, relative to its containing control frame.
    private(set) var frame: Rect = .zero {
        didSet {
            _global = nil
        }
    }

    /// Frame of node, if it is a Control, in global coordinates
    private var _global: Rect?
    var global: Rect {
        if _global == nil {
            _global = frame.relative(to: parent)
        }
        return _global!
    }

    /// Construct the root Node of an application, should only be called by the top-level Layout node.
    init(root view: any GenericView, application: Application?) {
        self.view = view
        self.application = application
    }

    /// Construct a Node for a given view.
    init(view: any GenericView, parent: Node?) {
        self.view = view
        self.parent = parent
        self.application = parent?.application
    }

    func invalidate() {
        application?.invalidate(node: self)
    }

    /// Update this node with a given view.
    final func update(view: any GenericView) {
        view.update(node: self)
        self.view = view
        self._global = nil
    }

    /// Add a child Node to the hierarchy.
    func add(at index: [Node].Index, node: Node) {
        children.insert(node, at: index)

        // TODO: Maintain `index` invariant
        // for i in index ..< children.endIndex {
        //     children[i].index = i
        // }
    }

    /// Remove a child node from the hierarchy.
    func remove(at index: [Node].Index) {
        children.remove(at: index).parent = nil

        // TODO: Do we need to maintain the `index` invariant on children? If so, update here.
    }

    /// Calculate the size of a node hierarchy by visiting each node. Control nodes should override this method with a method that actually calculates it's size.
    func size<T: LayoutVisitor>(visitor: inout T) {
        for child in children {
            child.size(visitor: &visitor)
        }
    }

    /// Performs the layout of a node hierarchy by visiting each node. Control nodes should override this method that actually performs its layout.
    func layout<T: LayoutVisitor>(visitor: inout T) {
        for child in children {
            child.layout(visitor: &visitor)
        }
    }

    func layout(size: Size) -> Size {
        frame.position = .zero
        frame.size = size
        return size
    }

    func move(to position: Position) {
        frame.position = position
    }

    func move(by position: Position) {
        frame.position += position
    }

    func draw(rect: Rect, into window: inout CellGrid<Cell?>) {
        guard let rect = global.intersection(rect) else { return }
        for child in children {
            child.draw(rect: rect, into: &window)
        }
    }

    func draw(rect: Rect, _ action: (Rect, Control) -> Void) {
        guard let rect = global.intersection(rect) else { return }

        if let control = self as? Control {
            action(rect, control)
        } else {
            for child in children {
                child.draw(rect: rect, action)
            }
        }
    }

    var description: String {
        "\(type(of: self.view))"
    }
}

fileprivate extension Position {
    @MainActor func relative(to node: Node?) -> Position {
        if let node {
            return node.global.position + self
        } else {
            return self
        }
    }
}

fileprivate extension Rect {
    @MainActor func relative(to node: Node?) -> Rect {
        if let node {
            return .init(
                position: node.global.position + position,
                size: size
            )
        } else {
            return self
        }
    }
}


extension Node {
    private func treeDescription(level: Int) -> String {
        var str = ""
        let indent = Array(repeating: " ", count: level * 2).joined()
        str += "\(indent)→ \(description)"

        for child in children {
            str += "\n"
            str += child.frameDescription(level: level + 1)
        }
        return str
    }

    var treeDescription: String {
        treeDescription(level: 0)
    }

    func frameDescription(level: Int) -> String {
        var str = ""
        let indent = Array(repeating: " ", count: level * 2).joined()
        str += "\(indent)→ \(description)"
        if frame != .zero {
            str += " \(global)"
        }
        for child in children {
            str += "\n"
            str += child.frameDescription(level: level + 1)
        }
        return str
    }

    var frameDescription: String {
        frameDescription(level: 0) + "\n"
    }
}
