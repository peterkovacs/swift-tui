
@MainActor
internal class Node {
    var view: any GenericView
    private(set) var root: RootNode?
    private(set) weak var parent: Node? = nil
    private(set) var children: [Node] = []

    /// Manipulation of this EnvironmentValues passing through this level.
    var environment: ((inout EnvironmentValues) -> Void)?

    init<T: View>(root view: T) {
        self.view = view.view
    }

    /// Construct a Node for a given view.
    init(view: any GenericView, parent: Node?) {
        self.view = view
        self.parent = parent
        self.root = parent?.root
    }



    /// Frame of this node, if it is a control, relative to its containing control frame.
    var frame: Rect = .zero {
        didSet {
            _global = nil
        }
    }

    /// Frame of node, if it is a Control, in global coordinates
    private var _global: Rect?
    var global: Rect {
        guard let _global else {
            let frame = relative(to: root)
            _global = frame
            return frame
        }

        return _global
    }
    func invalidate() {
        root?.invalidate(node: self)
    }

    func invalidateLayout() {
        parent?.invalidateLayout()
    }

    /// Update this node with a given view.
    func update(view: any GenericView) {
        self._global = nil
        view.update(node: self)
        self.view = view
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

    func focus<T: Visitor.Focus>(visitor: inout T) {
        for child in children {
            child.focus(visitor: &visitor)
        }
    }

    /// Calculate the size of a node hierarchy by visiting each node. Control nodes should override this method with a method that actually calculates it's size.
    func size<T: Visitor.Size>(visitor: inout T) {
        for child in children {
            child.size(visitor: &visitor)
        }
    }

    /// Performs the layout of a node hierarchy by visiting each node. Control nodes should override this method that actually performs its layout.
    func layout<T: Visitor.Layout>(visitor: inout T) {
        for child in children {
            child.layout(visitor: &visitor)
        }
    }

    func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }
        for child in children {
            child.draw(rect: rect, into: &window)
        }
    }

    /// Calls the callback with each Control in this node's hierarchy.
    ///
    /// - Parameter rect: The invalidated Rect in which to draw.
    /// - Parameter action: A callback that takes the intersection of the controls frame, the control, and the controls frame.
    ///
    /// This can be overridden by descendant types to provide custom logic for calculating the frame passed to action.
    func draw(rect: Rect, action: (_ invalidated: Rect, _ control: Control, _ frame: Rect) -> Void) {
        guard let rect = global.intersection(rect) else { return }

        if let control = self as? Control {
            action(rect, control, control.global)
        } else {
            for child in children {
                child.draw(rect: rect, action: action)
            }
        }
    }

    var description: String {
        "\(type(of: self.view))"
    }

    func relative(to ancestor: Node?) -> Rect {
        guard let ancestor, ancestor !== self else {
            return frame
        }

        var node = self
        var result = frame

        while let parent = node.parent, ancestor !== parent {
            result.position += parent.frame.position
            node = parent
        }

        result.position += node.frame.position

        return result
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
