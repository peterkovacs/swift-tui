public struct TextField: View, PrimitiveView {
    public let placeholder: String?
    public let text: Binding<String>
    public let onSubmit: (String) -> Void

    @Environment(\.placeholderColor) private var placeholderColor: Color

    public init(
        _ placeholder: String? = nil,
        text: Binding<String>,
        onSubmit: @escaping (String) -> Void
    ) {
        self.text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    func build(parent: Node?) -> Node {
        let node = TextFieldNode(
            view: self,
            parent: parent,
            text: text,
            placeholder: placeholder ?? "",
            placeholderColor: _placeholderColor,
            action: onSubmit
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? TextFieldNode else { fatalError("Unexpected node type") }

        node.set(references: self)
        node.placeholder = placeholder ?? ""
        node.placeholderColor = placeholderColor
        node.action = onSubmit
    }
}

extension EnvironmentValues {
    public var placeholderColor: Color {
        get { self[PlaceholderColorEnvironmentKey.self] }
        set { self[PlaceholderColorEnvironmentKey.self] = newValue }
    }
}

private struct PlaceholderColorEnvironmentKey: EnvironmentKey {
    static var defaultValue: Color { .default }
}

class TextFieldNode: DynamicPropertyNode, Control {
    @Binding var text: String
    var placeholder: String
    var placeholderColor: Color
    var action: (String) -> Void

    var cursorPosition: String.Index

    init<T: View>(
        view: T,
        parent: Node?,
        text: Binding<String>,
        placeholder: String,
        placeholderColor: Environment<Color>,
        action: @escaping (String) -> Void
    ) {
        self.placeholder = placeholder
        self.action = action
        self._text = text
        self.cursorPosition = text.wrappedValue.endIndex
        self.placeholderColor = .default
        super.init(view: view.view, parent: parent, content: view)
        self.placeholderColor = placeholderColor.wrappedValue
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
        return Size(width: Extended(max(text.count, placeholder.count)) + 1, height: 1)
    }

    private func word(before: String.Index) -> String.Index {
        if cursorPosition != text.startIndex {
            guard let endOfWord = text[..<cursorPosition].lastIndex(where: { $0.isNumber || $0.isLetter })
            else { return text.startIndex }

            guard let startOfWord = text[..<endOfWord]
                .lastIndex(where: { !$0.isNumber && !$0.isLetter })
            else { return text.startIndex }

            return text.index(after: startOfWord)
        }

        return text.startIndex
    }

    private func word(after: String.Index) -> String.Index {
        if cursorPosition != text.endIndex {
            let next = text.index(after: cursorPosition)

            guard let endOfWord = text[next...].firstIndex(where: { !$0.isNumber && !$0.isLetter })
            else { return text.endIndex }

            guard let startOfWord = text[endOfWord...].firstIndex(where: { $0.isNumber || $0.isLetter })
            else { return text.endIndex }

            return startOfWord
        }

        return text.endIndex
    }

    func handle(key: Key) -> Bool {
        if !text.indices.contains(cursorPosition) {
            cursorPosition = text.endIndex
        }

        switch(key) {
        case Key(.tab), Key(.tab, modifiers: .shift):
            return false

        case Key(.enter):
            action(text)
            self.text = ""
            self.cursorPosition = text.startIndex
            invalidate()
            return true

        case Key(.backspace):
            if !text.isEmpty, cursorPosition != text.startIndex {
                cursorPosition = text.index(before: cursorPosition)
                text.remove(at: cursorPosition)
                invalidate()
            }
            return true

        case Key(.delete):
            if !text.isEmpty, cursorPosition != text.startIndex {
                cursorPosition = text.index(before: cursorPosition)
                text.remove(at: cursorPosition)
                invalidate()
            }
            return true

        case Key(.left), Key("b", modifiers: .ctrl):
            if cursorPosition != text.startIndex {
                cursorPosition = text.index(before: cursorPosition)
                invalidate()
                return true
            }

        case Key(.left, modifiers: .ctrl), Key(.left, modifiers: .alt):
            if cursorPosition != text.startIndex {
                cursorPosition = word(before: cursorPosition)
                invalidate()
                return true
            }

        case Key(.right, modifiers: .ctrl), Key(.right, modifiers: .alt):
            if cursorPosition != text.endIndex {
                cursorPosition = word(after: cursorPosition)
                invalidate()
                return true
            }

        case Key(.right), Key("f", modifiers: .ctrl):
            if cursorPosition != text.endIndex {
                cursorPosition = text.index(after: cursorPosition)
                invalidate()
                return true
            }

        case Key("k", modifiers: .ctrl):
            if cursorPosition != text.endIndex {
                text.removeSubrange(cursorPosition...)
                invalidate()
            }
            return true

        case Key("w", modifiers: .ctrl):
            // If there is a whitespace characters to our left, skip over
            // to find the first non-alpha-numeric
            if cursorPosition != text.startIndex {
                let startOfWord = word(before: cursorPosition)
                text.removeSubrange(startOfWord..<cursorPosition)
                cursorPosition = startOfWord

                invalidate()
                return true
            }
            return true


        case Key("u", modifiers: .ctrl):
            if !text.isEmpty {
                text = ""
                cursorPosition = text.endIndex
                invalidate()
            }
            return true

        case Key("a", modifiers: .ctrl):
            if cursorPosition != text.endIndex {
                cursorPosition = text.startIndex
                invalidate()
            }
            return true

        case Key("e", modifiers: .ctrl):
            if cursorPosition != text.endIndex {
                cursorPosition = text.endIndex
                invalidate()
            }
            return true

        case _ where key.modifiers.isEmpty && !key.isControl:

            if case .char(let value) = key.key {
                text.insert(.init(value), at: cursorPosition)
                cursorPosition = text.index(after: cursorPosition)
                invalidate()
                return true
            }

        default:
            break
        }

        return false
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        if text.isEmpty {
            for (position, character) in zip(global.indices, placeholder.indices) where rect.contains(position) {
                window.write(at: position, default: .init(char: placeholder[character])) {
                    $0.char = placeholder[character]
                    // TODO: Only do this if we're the focused element.
                    $0.attributes.inverted = character == placeholder.startIndex
                    $0.foregroundColor = placeholderColor
                }
            }
        } else {
            for (position, character) in zip(global.indices, text.indices) where rect.contains(position) {
                window.write(at: position, default: .init(char: text[character])) {
                    $0.char = text[character]
                    // TODO: Only do this if we're the focused element.
                    $0.attributes.inverted = character == cursorPosition
                    $0.foregroundColor = placeholderColor
                }
            }

        }
    }
}
