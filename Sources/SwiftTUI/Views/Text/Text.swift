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
    
    var text: Text.Value {
        didSet { splitText(text: text) }
    }

    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var strikethrough: Bool = false
    var foregroundColor: Color = .default
    let lineBreaker: KnuthPlassLineBreaker
    var paragraphs: [[ArraySlice<Character>]] = []
    var wordSizes: [LineBreakingInput] = []

    private func splitText(text: Text.Value) {
        paragraphs = switch text {
        case .string(let string):
            string.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map { $0.split(omittingEmptySubsequences: false, whereSeparator: \.isWhitespace) }

        case .attributed(let string):
           string.characters.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map {
                $0.split(omittingEmptySubsequences: false, whereSeparator: \.isWhitespace)
            }
        }

        wordSizes = paragraphs.map { line in
            line.map { LineItemInput(size: Extended($0.count), spacing: 1) }
        }
    }

    struct LineBreakIter: IteratorProtocol, Sequence {
        /// The string that we are outputting.
        let string: String
        /// The index of the next character to be output.
        var stringIndex: String.Index

        /// The bounds to display the string in.
        let frame: Rect
        /// The current position in frame that is being written. We must write to every position in the frame, even if the line break has already happened.
        var position: Position

        /// A list of lines, one for each paragraph in the output. A paragraph consists of 0 or more lines
        let paragraphs: [LineBreakingOutput] // == [[LineOutput]] == [[[LineItemOutput]]]

        /// The current paragraph that we are iterating.
        var paragraphsIndex: [LineBreakingOutput].Index
        /// The current line that we are iterating.
        var lineIndex: [LineOutput].Index
        /// The current word that we are iterating.
        var wordIndex: [LineItemOutput].Index
        /// Our position within the word. When this changes, we should increment ``stringIndex``.
        var index: Extended

        init(
            frame: Rect,
            string: String,
            paragraphs: [LineBreakingOutput]
        ) {
            self.frame = frame
            self.position = .init(column: frame.minColumn, line: frame.minLine)

            self.string = string
            self.stringIndex = string.startIndex
            self.paragraphs = paragraphs
            self.paragraphsIndex = paragraphs.startIndex
            self.lineIndex = paragraphs[paragraphs.startIndex].startIndex
            self.wordIndex = paragraphs[paragraphs.startIndex][lineIndex].startIndex
            self.index = 0
        }

        mutating func next() -> (Position, Cell)? {
            // If we're done with the line then we can advance the lineIndex.
            if position.column > frame.maxColumn {
                lineIndex = lineIndex.advanced(by: 1)
                position.column = frame.minColumn
                position.line += 1

                if position.line > frame.maxLine {
                    return nil
                }

                stringIndex = string.index(stringIndex, offsetBy: 1)

                // If we're done with the paragraph, we can advance the paragraphIndex
                // This should be safe since we checked that we're still in the frame above.
                if lineIndex >= paragraphs[paragraphsIndex].endIndex {
                    paragraphsIndex = paragraphsIndex.advanced(by: 1)
                    lineIndex = 0
                }

                wordIndex = 0
                index = 0
            }

            defer {
                position.column += 1
            }

            // Check if we're done with the current word.
            if
                paragraphsIndex < paragraphs.endIndex,
                lineIndex < paragraphs[paragraphsIndex].endIndex,
                wordIndex < paragraphs[paragraphsIndex][lineIndex].endIndex
            {
                let word = paragraphs[paragraphsIndex][lineIndex][wordIndex]
                if index >= word.leadingSpace + word.size {
                    index = 0
                    wordIndex = wordIndex.advanced(by: 1)
                }

                if wordIndex < paragraphs[paragraphsIndex][lineIndex].endIndex {
                    defer {
                        index += 1
                        stringIndex = string.index(after: stringIndex)
                    }

                    return (
                        position,
                        .init(char: string[stringIndex])
                    )
                }
            }

            return (
                position,
                .init(char: " ")
            )
        }
    }

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
        self.lineBreaker = KnuthPlassLineBreaker()
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

        splitText(text: text)
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

    func lineBreaks(for width: Extended) -> [LineBreakingOutput] {
        wordSizes.map {
            lineBreaker.wrapItemsToLines(items: $0, in: width)
        }
    }

    func size(proposedSize: Size) -> Size {

        // Fast out for small strings in big sizes.
        switch text {
        case .string(let string):
            let width = Extended(string.count)
            if width <= proposedSize.width {
                return .init(width: Extended(string.count), height: 1)
            }

        case .attributed(let attributed):
            let width = Extended(attributed.characters.count)
            if width <= proposedSize.width {
                return .init(width: Extended(attributed.characters.count), height: 1)
            }
        }

        // minimum width is going to be the size of the longest word
        let minimumWidth = Extended(
            paragraphs.reduce(into: 0) { max, line in
                max = line.reduce(into: max) { max, word in max = Swift.max(max, word.count) }
            }
        )

        // Calculate line breaks based on this width.
        let lineBreaks = lineBreaks(for: proposedSize.width < minimumWidth ? minimumWidth : proposedSize.width)

        // Calculate the height and width
        return lineBreaks.reduce(into: Size.zero) { size, lines in
            // size.height += 1
            size.height += Extended(lines.count)

            size.width = lines.reduce(into: size.width) { result, line in
                result = max(result, line.reduce(into: 0) { $0 += $1.leadingSpace + $1.size })
            }
        }
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        let lineBreaks = lineBreaks(for: frame.size.width)

        switch text {
        case .string(let text):
            var iter = LineBreakIter(frame: global, string: text, paragraphs: lineBreaks)
            for (position, cell) in iter where rect.contains(position) {
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
            var position = rect.indices.makeIterator()
            let characters = text.runs.lazy.flatMap { run in
                text.characters[run.range].lazy.map {
                    (position.next(), run.bold, run.italic, run.underline, run.strikethrough, run.inverted, $0)
                }
            }

            for (position, bold, italic, underline, strikethrough, inverted, char) in characters {
                guard let position else { break }
                window.write(at: position, default: .init(char: char)) {
                    $0.char = char
                    $0.attributes.bold = bold ?? self.bold
                    $0.attributes.italic = italic ?? self.italic
                    $0.attributes.underline = underline ?? self.underline
                    $0.attributes.strikethrough = strikethrough ?? self.strikethrough
                    if let inverted {
                        $0.attributes.inverted = inverted
                    }
                    $0.foregroundColor = foregroundColor
                }
            }
        }
    }

    override var description: String {
        "Text:\(text)"
    }
}
