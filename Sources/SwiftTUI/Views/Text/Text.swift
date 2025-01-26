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

final class TextNode: DynamicPropertyNode, Control {
    
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
            layout: .init(node: self) { [weak self] rect in
                guard let self else { return .zero }
                return layout(rect: rect)
            } frame: { [weak self] rect in
                guard let self else { return .zero }
                frame = rect
                return rect
            } global: { [weak self] in
                self?.global ?? .zero
            }
        )
    }

    override func layout(rect: Rect) -> Rect {
        super.layout(
            rect: .init(
                position: rect.position,
                size: self.size(proposedSize: rect.size)
            )
        )
    }

    func size(proposedSize: Size) -> Size {
        switch text {
        case .string(let text):
            let paragraphs = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

            let maximumWidth = Size(
                width: paragraphs.reduce(0) { max($0, .init($1.count)) },
                height: Extended(paragraphs.count)
            )

            // Early Out for containing sizes.
            if proposedSize.width >= maximumWidth.width {
                return maximumWidth
            }

            // Calculate the minimum width
            let paragraphWords = paragraphs.map {
                $0.split(omittingEmptySubsequences: false, whereSeparator: \.isWhitespace)
            }

            let minimumWidth: Extended = paragraphWords.reduce(into: 0) { minimumWidth, paragraph in
                minimumWidth = paragraph.reduce(into: minimumWidth) { minimumWidth, word in
                    minimumWidth = max(minimumWidth, .init(word.count))
                }
            }

            // Calculate the height based on the given width.
            var size = Size(
                width: minimumWidth > proposedSize.width ? minimumWidth : proposedSize.width,
                height: 0
            )

            for paragraph in paragraphWords {
                size.height += 1
                var widthOfLine: Extended = 0

                for word in paragraph {
                    let widthOfWord: Extended = .init(word.count)
                    if widthOfLine + widthOfWord <= size.width {
                        widthOfLine += widthOfWord
                        widthOfLine += 1 // space after word.
                    } else {
                        size.height += 1
                        widthOfLine = widthOfWord
                    }
                }
            }

            return size
        case .attributed(let text):
            return .zero
        }
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        switch text {
        case .string(let text):
            for (position, cell) in LineIterator(rect: global, string: text) where rect.contains(position) {
                window.write(at: position, default: cell) {
                    $0.char = cell.char
                    $0.attributes.bold = bold
                    $0.attributes.italic = italic
                    $0.attributes.underline = underline
                    $0.attributes.strikethrough = strikethrough
                    $0.foregroundColor = foregroundColor
                }

            }
            
            
        case .attributed(let text):
            break
            //            var position = rect.indices.makeIterator()
            //            let characters = text.runs.lazy.flatMap { run in
            //                text.characters[run.range].lazy.map {
            //                    (position.next(), run.bold, run.italic, run.underline, run.strikethrough, run.inverted, $0)
            //                }
            //            }
            //
            //            for (position, bold, italic, underline, strikethrough, inverted, char) in characters {
            //                guard let position else { break }
            //                window.write(at: position, default: .init(char: char)) {
            //                    $0.char = char
            //                    $0.attributes.bold = bold ?? self.bold
            //                    $0.attributes.italic = italic ?? self.italic
            //                    $0.attributes.underline = underline ?? self.underline
            //                    $0.attributes.strikethrough = strikethrough ?? self.strikethrough
            //                    if let inverted {
            //                        $0.attributes.inverted = inverted
            //                    }
            //                    $0.foregroundColor = foregroundColor
            //                }
            //            }
        }
    }

    override var description: String {
        "Text:\(text)"
    }
}
