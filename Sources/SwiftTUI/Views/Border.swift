extension View {
    public func border(_ color: Color? = nil, style: BorderStyle = .default, edges: Edges = .all) -> some View {
        Border(style: style, edges: edges, color: color, content: self)
    }
}

public struct BorderStyle: Equatable {
    let topLeft: Character
    let top: Character
    let topRight: Character
    let left: Character
    let right: Character
    let bottomLeft: Character
    let bottom: Character
    let bottomRight: Character

    public init(topLeft: Character, top: Character, topRight: Character, left: Character, right: Character, bottomLeft: Character, bottom: Character, bottomRight: Character) {
        self.topLeft = topLeft
        self.top = top
        self.topRight = topRight
        self.left = left
        self.right = right
        self.bottomLeft = bottomLeft
        self.bottom = bottom
        self.bottomRight = bottomRight
    }

    public init(topLeft: Character, topRight: Character, bottomLeft: Character, bottomRight: Character, horizontal: Character, vertical: Character) {
        self.topLeft = topLeft
        self.top = horizontal
        self.topRight = topRight
        self.left = vertical
        self.right = vertical
        self.bottomLeft = bottomLeft
        self.bottom = horizontal
        self.bottomRight = bottomRight
    }

    /// ```
    /// ┌──┐
    /// └──┘
    /// ```
    public static var `default`: BorderStyle {
        BorderStyle(topLeft: "┌", topRight: "┐", bottomLeft: "└", bottomRight: "┘", horizontal: "─", vertical: "│")
    }

    /// ```
    /// ╭──╮
    /// ╰──╯
    /// ```
    public static var rounded: BorderStyle {
        BorderStyle(topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯", horizontal: "─", vertical: "│")
    }

    /// ```
    /// ┏━━┓
    /// ┗━━┛
    /// ```
    public static var heavy: BorderStyle {
        BorderStyle(topLeft: "┏", topRight: "┓", bottomLeft: "┗", bottomRight: "┛", horizontal: "━", vertical: "┃")
    }

    /// ```
    /// ╔══╗
    /// ╚══╝
    /// ```
    public static var double: BorderStyle {
        BorderStyle(topLeft: "╔", topRight: "╗", bottomLeft: "╚", bottomRight: "╝", horizontal: "═", vertical: "║")
    }
}

struct Border<Content: View>: View, PrimitiveView {
    @Environment(\.foregroundColor) var foregroundColor
    var style: BorderStyle
    var edges: Edges
    var color: Color?
    let content: Content

    func build(parent: Node?) -> Node {
        let node = BorderNode(
            view: self,
            parent: parent,
            content: self,
            style: style,
            edges: edges
        )

        node.color = color ?? foregroundColor
        node.add(at: 0, node: content.view.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let node = node as? BorderNode else { fatalError() }

        node.set(references: self)
        node.style = style
        node.edges = edges
        node.color = color ?? foregroundColor
        node._sizeVisitor = nil
        node._layoutVisitor = nil
    }
}

final class BorderNode: ComposedNode {
    var style: BorderStyle
    var edges: Edges
    var color: Color

    var borderSize: Size {
        Size(
            width: (edges.contains(.left) ? 1 : 0) + (edges.contains(.right) ? 1 : 0),
            height: (edges.contains(.top) ? 1 : 0) + (edges.contains(.bottom) ? 1 : 0)
        )
    }

    var borderPosition: Position {
        .init(
            column: edges.contains(.left) ? 1 : 0,
            line: edges.contains(.top) ? 1 : 0
        )
    }

    fileprivate var _sizeVisitor: BorderVisitor? = nil
    var sizeVisitor: BorderVisitor {
        let visitor = _sizeVisitor ?? BorderVisitor(children: children) { $0.size(visitor: &$1) }
        _sizeVisitor = visitor

        return visitor
    }

    fileprivate var _layoutVisitor: BorderVisitor? = nil
    var layoutVisitor: BorderVisitor {
        let visitor = _layoutVisitor ?? BorderVisitor(children: children) { $0.layout(visitor: &$1) }
        _layoutVisitor = visitor

        return visitor
    }


    init<Content: View>(view: any GenericView, parent: Node?, content: Content, style: BorderStyle, edges: Edges) {
        self.style = style
        self.color = .default
        self.edges = edges

        super.init(view: view, parent: parent, content: content)
    }

    struct BorderVisitor: LayoutVisitor {
        var visited: [(node: Control, size: (Size) -> Size)]

        fileprivate init(
            children: [Node],
            action: (Node, inout Self) -> Void
        ) {
            self.visited = []

            for child in children {
                action(child, &self)
            }
        }

        mutating func visit(node: any Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }
    }

    override func layout<T>(visitor: inout T) where T : LayoutVisitor {
        for child in layoutVisitor.visited {
            visitor.visit(node: child.node) { [borderPosition, borderSize] (size: Size) in
                defer {
                    child.node.move(
                        by: borderPosition
                    )
                }

                return child.size( size - borderSize ) + borderSize
            }
        }
    }

    override func size<T>(visitor: inout T) where T : LayoutVisitor {
        let borderSize = borderSize

        for child in sizeVisitor.visited {
            visitor.visit(node: child.node) { (size: Size) in
                child.size( size - borderSize ) + borderSize
            }
        }
    }

    override func draw(rect: Rect, into window: inout CellGrid<Cell?>) {
        // We're (potentially) drawing outside of the given `rect` to make
        // the code identifying the border pixels a little simpler.

        func draw(position: Position, char: Character) {
            var cell = window[position, default: .init(char: " ")]
            cell.char = char
            cell.foregroundColor = color
            window[position] = cell
        }

        self.draw(rect: rect) { rect, node in
            let frame = Rect(
                position: node.global.position - borderPosition,
                size: node.global.size + borderSize
            )

            if edges.contains(.top) {
                for i in frame.top { draw(position: i, char: style.top) }
            }
            if edges.contains(.right) {
                for i in frame.right { draw(position: i, char: style.right) }
            }
            if edges.contains(.bottom) {
                for i in frame.bottom { draw(position: i, char: style.bottom) }
            }
            if edges.contains(.left) {
                for i in frame.left { draw(position: i, char: style.left) }
            }

            if edges.contains(.top) && edges.contains(.right) {
                draw(position: .init(column: frame.maxColumn, line: frame.minLine), char: style.topRight)
            }
            if edges.contains(.top) && edges.contains(.left) {
                draw(position: .init(column: frame.minColumn, line: frame.minLine), char: style.topLeft)
            }
            if edges.contains(.bottom) && edges.contains(.left) {
                draw(position: .init(column: frame.minColumn, line: frame.maxLine), char: style.bottomLeft)
            }
            if edges.contains(.bottom) && edges.contains(.right) {
                draw(position: .init(column: frame.maxColumn, line: frame.maxLine), char: style.bottomRight)
            }
        }

        super.draw(rect: rect, into: &window)
    }

    override func draw(rect: Rect, _ action: (Rect, Control) -> Void) {
        // When called by node higher in the hierarchy, we want to draw any children, while adjusting their size
        // This can take the place of the standard draw method which accomplishes the same thing.
        for (node, _) in sizeVisitor.visited {
            guard
                let frame = Rect(
                    position: node.global.position - borderPosition,
                    size: node.global.size + borderSize
                ).intersection(rect)
            else { continue }

            action(frame, node)
        }
    }

    override var description: String {
        let positions = sizeVisitor.visited.map(\.node).map(\.global)
            .map { Rect(position: $0.position - borderPosition, size: $0.size + borderSize) }
        return "Border:\(positions)"
    }
}
