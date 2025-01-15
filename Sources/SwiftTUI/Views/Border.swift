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

        node.view = self
        node.set(references: self)
        node.style = style
        node.edges = edges
        node.color = color ?? foregroundColor

        node.children[0].update(view: content.view)
    }
}

final class BorderNode: PaddingNode {
    var style: BorderStyle
    var color: Color

    var borderSize: Size {
        paddingSize
    }

    var borderPosition: Position {
        paddingPosition
    }

    init<Content: View>(view: any GenericView, parent: Node?, content: Content, style: BorderStyle, edges: Edges) {
        self.style = style
        self.color = .default

        super.init(view: view, parent: parent, content: content, size: 1, edges: edges)
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        // We're (potentially) drawing outside of the given `rect` to make
        // the code identifying the border pixels a little simpler.

        func draw(position: Position, char: Character) {
            var cell = window[position, default: .init(char: " ")]
            cell.char = char
            cell.foregroundColor = color
            window[position] = cell
        }

        super.draw(rect: rect, into: &window)
        self.draw(rect: rect) { invalidated, _, frame in
            if edges.contains(.top) {
                for i in frame.top where invalidated.contains(i) { draw(position: i, char: style.top) }
            }
            if edges.contains(.right) {
                for i in frame.right where invalidated.contains(i) { draw(position: i, char: style.right) }
            }
            if edges.contains(.bottom) {
                for i in frame.bottom where invalidated.contains(i) { draw(position: i, char: style.bottom) }
            }
            if edges.contains(.left) {
                for i in frame.left where invalidated.contains(i) { draw(position: i, char: style.left) }
            }

            if edges.contains(.top) && edges.contains(.right) && invalidated.contains(frame.topRight) {
                draw(position: frame.topRight, char: style.topRight)
            }
            if edges.contains(.top) && edges.contains(.left) && invalidated.contains(frame.topLeft) {
                draw(position: frame.topLeft, char: style.topLeft)
            }
            if edges.contains(.bottom) && edges.contains(.left) && invalidated.contains(frame.bottomLeft) {
                draw(position: frame.bottomLeft, char: style.bottomLeft)
            }
            if edges.contains(.bottom) && edges.contains(.right) && invalidated.contains(frame.bottomRight) {
                draw(position: frame.bottomRight, char: style.bottomRight)
            }
        }

    }

    override func draw(rect: Rect, action: (Rect, Control, Rect) -> Void) {
        // When called by node higher in the hierarchy, we want to draw any children, while adjusting their size
        // This can take the place of the standard draw method which accomplishes the same thing.
        for element in layoutVisitor.visited {
            // node.global is the position of the node, but doesn't allow any descendant Modifiers like ourselves to modify the frame.
            //
            let frame = element.global() - borderPosition + borderSize
            guard
                let invalidated = frame.intersection(rect)
            else { continue }

            action(invalidated, element.node, frame)
        }
    }

    override var description: String {
        return "Border:\(layoutVisitor.visited.map { $0.global() - borderPosition + borderSize })"
    }
}
