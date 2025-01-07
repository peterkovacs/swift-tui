
@MainActor
internal class Node {
    var view: any GenericView

    private(set) var application: Application?
    private(set) weak var parent: Node? = nil
    private(set) var children: [Node] = []

    /// Frame of this node, if it is a control, relative to its containing control frame.
    private(set) var frame: Rect = .zero
    var bounds: Size { frame.size }

    static func root<T: View>(_ view: T, application: Application? = nil) -> Node {
        let node = VStack { view }.view.build(parent: nil)
        node.application = application
        return node
    }

    init(view: any GenericView, parent: Node? = nil) {
        self.view = view
        self.parent = parent
        self.application = parent?.application

        // view.build(node: self)
    }

    func invalidate() {
        application?.invalidate(node: self)
    }

    func update(view: any GenericView) {
        view.update(node: self)
        self.view = view
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

    func cell(at position: Position, covering: Cell?) -> Cell? {
        var result: Cell? = nil
        for child in children {
            if let cell = child.cell(at: position - frame.position, covering: result) {
                result = cell
            }
        }
        return result
    }

    var description: String {
        "\(type(of: self.view))"
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
            str += " \(frame)"
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
