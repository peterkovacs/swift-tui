import Foundation

/// A basic single line of text.
///
public struct Text: View, PrimitiveView {
    enum Value {
        case string(String)
        case attributed(AttributedString)
    }

    @Environment(\.bold) var bold
    @Environment(\.italic) var italic
    @Environment(\.underline) var underline
    @Environment(\.strikethrough) var strikethrough
    @Environment(\.foregroundColor) var foregroundColor

    // TODO: Read text attributes from Environment.

    let text: Value

    public init(_ text: String) {
        self.text = .string(text)
    }

    public init(_ text: AttributedString) {
        self.text = .attributed(text)
    }

    func build(parent: Node?) -> Node {
        let node = TextNode(
            view: self,
            parent: parent,
            text: text,
            bold: _bold,
            italic: _italic,
            underline: _underline,
            strikethrough: _strikethrough,
            foregroundColor: _foregroundColor
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? TextNode else {
            fatalError("Invalid node type")
        }

        node.set(references: self)

        node.text = text
        node.bold = bold
        node.italic = italic
        node.underline = underline
        node.strikethrough = strikethrough
        node.foregroundColor = foregroundColor
    }
}

final class TextNode: ComposedNode, Control {
    var text: Text.Value
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var strikethrough: Bool = false
    var foregroundColor: Color = .default

    init(
        view: Text,
        parent: Node?,
        text: Text.Value,
        bold: Environment<Bool>,
        italic: Environment<Bool>,
        underline: Environment<Bool>,
        strikethrough: Environment<Bool>,
        foregroundColor: Environment<Color>
    ) {
        self.text = text
        super.init(
            view: view,
            parent: parent,
            content: view
        )
        self.bold = bold.wrappedValue
        self.italic = italic.wrappedValue
        self.underline = underline.wrappedValue
        self.strikethrough = strikethrough.wrappedValue
        self.foregroundColor = foregroundColor.wrappedValue
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: .init(node: self, size: size(proposedSize:)))
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self, layout: layout(rect:)) {
                self.frame = $0
            } global: {
                self.global
            }
        )
    }

    override func layout(rect: Rect) -> Rect {
        // TODO: deal with size that doesn't fit the text
        super.layout(
            rect: .init(
                position: rect.position,
                size: self.size(proposedSize: rect.size)
            )
        )
    }

    func size(proposedSize: Size) -> Size {
        switch text {
        case .string(let string):
            // TODO: handle multi-line and proposedSize that spills our text onto multiple lines.
            return .init(width: Extended(string.count), height: 1)

        case .attributed(let attributed):
            // TODO: Deal with attributed
            return .init(width: Extended(attributed.characters.count), height: 1)
        }
    }

    override func draw(rect: Rect, into window: inout CellGrid<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        switch text {
        case .string(let text):
            for (position, char) in zip(rect.indices, text) {
                var result = window[position, default: .init(char: char)]
                result.char = char
                result.attributes.bold = bold
                result.attributes.italic = italic
                result.attributes.underline = underline
                result.attributes.strikethrough = strikethrough
                result.foregroundColor = foregroundColor
                
                window[position] = result
            }

        case .attributed(let text):
            var position = rect.indices.makeIterator()
            let characters = text.runs.lazy.flatMap { run in
                text.characters[run.range].lazy.map {
                    (position.next(), run.bold, run.italic, run.underline, run.strikethrough, run.inverted, $0)
                }
            }

            for (position, bold, italic, underline, strikethrough, inverted, char) in characters {
                guard let position else { break }
                var result = window[position, default: .init(char: char)]
                result.char = char

                result.attributes.bold = bold ?? self.bold
                result.attributes.italic = italic ?? self.italic
                result.attributes.underline = underline ?? self.underline
                result.attributes.strikethrough = strikethrough ?? self.strikethrough

                if let value = inverted { result.attributes.inverted = value }

                window[position] = result
            }
        }
    }

    override var description: String {
        "Text:\(text)"
    }
}
