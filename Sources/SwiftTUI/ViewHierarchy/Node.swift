
@MainActor
internal class Node {
    var view: any GenericView

    private(set) var application: Application?
    private(set) weak var parent: Node? = nil
    private(set) var children: [Node] = []

    /// Frame of this node, if it is a control, relative to its containing control frame.
    private(set) var frame: Rect = .zero {
        didSet {
            _relative = nil
        }
    }

    private var _relative: Rect?
    var relative: Rect {
        if _relative == nil {
            _relative = frame.relative(to: parent)
        }
        return _relative!
    }

    var bounds: Size { frame.size }

    init(root view: any GenericView, application: Application?) {
        self.view = view
        self.application = application
    }

    init(view: any GenericView, parent: Node?) {
        self.view = view
        self.parent = parent
        self.application = parent?.application
    }

    func invalidate() {
        application?.invalidate(node: self)
    }

    final func update(view: any GenericView) {
        view.update(node: self)
        self.view = view
        self._relative = nil
    }

    func add(at index: [Node].Index, node: Node) {
        children.insert(node, at: index)

        // TODO: Maintain `index` invariant
        // for i in index ..< children.endIndex {
        //     children[i].index = i
        // }
    }

    func remove(at index: [Node].Index) {
        children.remove(at: index).parent = nil

        // TODO: Do we need to maintain the `index` invariant on children? If so, update here.
    }

    func size<T: LayoutVisitor>(visitor: inout T) {
        for child in children {
            child.size(visitor: &visitor)
        }
    }

    func layout<T: LayoutVisitor>(visitor: inout T) {
        for child in children {
            child.layout(visitor: &visitor)
        }
    }

    func layout(size: Size) -> Size {
        frame.size = size
        return size
    }

    func move(to position: Position) {
        frame.position = position
//
//        for child in children {
//            child.move(to: child.frame.position + position)
//        }
    }

    func draw(rect: Rect, into window: inout CellGrid<Cell?>) {
        guard let frame = rect.intersection(relative) else { return }
        for child in children {
            child.draw(rect: frame, into: &window)
        }
    }

    var description: String {
        "\(type(of: self.view))"
    }
}

fileprivate extension Position {
    @MainActor func relative(to node: Node?) -> Position {
        if let node {
            return node.relative.position + self
        } else {
            return self
        }
    }
}

fileprivate extension Rect {
    @MainActor func relative(to node: Node?) -> Rect {
        if let node {
            return .init(
                position: node.relative.position + position,
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
            str += " \(relative)"
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
