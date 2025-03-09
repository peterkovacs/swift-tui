public struct TextField: View, PrimitiveView {
    public let placeholder: String?
    public let text: Binding<String>
    public let onSubmit: (String) -> Void

    @Environment(\.placeholderColor) private var placeholderColor: Color
    @Environment(\.foregroundColor) private var foregroundColor: Color

    public init(
        _ placeholder: String? = nil,
        text: Binding<String>,
        onSubmit: @escaping (String) -> Void
    ) {
        self.text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = TextFieldNode(
            view: self,
            parent: parent,
            root: root,
            text: text,
            placeholder: placeholder ?? "",
            placeholderColor: _placeholderColor,
            foregroundColor: _foregroundColor,
            action: onSubmit
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? TextFieldNode else { fatalError("Unexpected node type") }

        node.set(references: self)
        node.placeholder = placeholder ?? ""
        node.placeholderColor = placeholderColor
        node.foregroundColor = foregroundColor
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

final class TextFieldNode: DynamicPropertyNode, Control {
    @Binding var text: String
    var placeholder: String { didSet { if placeholder != oldValue { invalidateLayout() } } }
    var placeholderColor: Color
    var foregroundColor: Color
    var action: (String) -> Void
    var isFocused: Bool = false {
        didSet {
            if oldValue != isFocused {
                invalidate()
            }
        }
    }

    var cursorPosition: String.Index

    init<T: View>(
        view: T,
        parent: Node?,
        root: RootNode?,
        text: Binding<String>,
        placeholder: String,
        placeholderColor: Environment<Color>,
        foregroundColor: Environment<Color>,
        action: @escaping (String) -> Void
    ) {
        self.placeholder = placeholder
        self.action = action
        self._text = text
        self.cursorPosition = text.wrappedValue.endIndex
        self.placeholderColor = .default
        self.foregroundColor = .default
        super.init(view: view.view, parent: parent, root: root, content: view)
        self.placeholderColor = placeholderColor.wrappedValue
        self.foregroundColor = foregroundColor.wrappedValue
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: sizeElement)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(layout: layoutElement)
    }

    override func focus<T: Visitor.Focus>(visitor: inout T) {
        visitor.visit(focus: focusableElement)
    }

    func layout(rect: Rect) -> Rect {
        frame = .init(
            position: rect.position,
            size: self.size(proposedSize: rect.size)
        )

        return frame
    }

    func size(proposedSize: Size) -> Size {
        return Size(
            width: max(1, proposedSize.width),
            height: 1
        )
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

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }

        if text.isEmpty {
            for (position, character) in zip(global.indices, placeholder.indices) where rect.contains(position) {
                window.write(at: position, default: .init(char: placeholder[character])) {
                    $0.char = placeholder[character]
                    $0.attributes.inverted = isFocused && character == cursorPosition
                    $0.foregroundColor = placeholderColor
                }
            }
        } else {
            let text = text + " "
            for (position, character) in zip(global.indices, text.indices) where rect.contains(position) {
                window.write(at: position, default: .init(char: text[character])) {
                    $0.char = text[character]
                    $0.attributes.inverted = isFocused && character == cursorPosition
                    $0.foregroundColor = foregroundColor
                }
            }
        }
    }

    override var description: String {
        "TextField:\"\(String(describing: text))\" (\(cursorPosition.utf16Offset(in: text)))\(isFocused ? " FOCUSED" : "")"
    }
}

extension TextFieldNode: Focusable {
    func becomeFirstResponder() {
        isFocused = true
    }
    
    func resignFirstResponder() {
        isFocused = false
    }
    
    var isFocusable: Bool { true }

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
            if cursorPosition != text.startIndex {
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
}
