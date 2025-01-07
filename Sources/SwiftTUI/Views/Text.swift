import Foundation

/// A basic single line of text.
///
public struct Text: View, PrimitiveView {
    enum Value {
        case string(String)
        case attributed(AttributedString)
    }

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
            text: text
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? TextNode else {
            fatalError("Invalid node type")
        }

        node.text = text
    }
}

final class TextNode: Node, Control {
    var text: Text.Value

    init(view: any GenericView, parent: Node?, text: Text.Value) {
        self.text = text
        super.init(view: view, parent: parent)
    }

    override func size<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self, size: size(proposedSize:))
    }

    override func layout<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self, size: layout(size:))
    }

    override func layout(size: Size) -> Size {
        // TODO: deal with size that doesn't fit the text
        super.layout(size: self.size(proposedSize: size))
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

    override func cell(at position: Position, covering: Cell?) -> Cell? {
        guard frame.contains(position) else { return nil }

        let position = position - frame.position

        switch text {
        case .string(let text):
            var covering = covering ?? .init(char: " ")
            covering.char = text[text.index(text.startIndex, offsetBy: position.column.intValue)]
            return covering

        case .attributed(let attributedText):
            let characters = attributedText.characters
            let i = characters.index(characters.startIndex, offsetBy: position.column.intValue)
            let char = attributedText[i ..< characters.index(after: i)]

            var covering = covering ?? .init(char: " ")
            covering.char = char.characters[char.startIndex]

            if let bold = char.bold {
                covering.attributes.bold = bold
            }
            if let italic = char.italic {
                covering.attributes.italic = italic
            }
            if let underline = char.underline {
                covering.attributes.underline = underline
            }
            if let strikethrough = char.strikethrough {
                covering.attributes.strikethrough = strikethrough
            }
            if let inverted = char.inverted {
                covering.attributes.inverted = inverted
            }

            return covering
        }
    }

    override var description: String {
        "Text:\(text)"
    }
}
