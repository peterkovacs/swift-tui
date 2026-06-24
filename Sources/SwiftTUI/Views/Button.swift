import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let action: @MainActor () -> Void
    let label: Label

    public init(action: @escaping @MainActor () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public init(_ label: String, action: @escaping @MainActor () -> Void) where Label == Text {
        self.action = action
        self.label = Text(label)
    }

    public init(_ label: AttributedString, action: @escaping @MainActor () -> Void) where Label == Text {
        self.action = action
        self.label = Text(label)
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = ButtonNode(
            view: self,
            parent: parent,
            root: root,
            action: action
        )

        node.add(at: 0, node: label.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        guard let node = node as? ButtonNode else { fatalError("Unexpected node type") }

        node.action = action
        node.children[0].update(view: label.view)
    }
}

final class ButtonNode: HStackNode {
    var action: @MainActor () -> Void
    var isFocused: Bool { didSet { if isFocused != oldValue { invalidate() } } }

    init(view: any GenericView, parent: Node?, root: RootNode?, action: @escaping @MainActor () -> Void) {
        self.action = action
        self.isFocused = false
        super.init(view: view, parent: parent, root: root, alignment: .center, spacing: 1)
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        super.draw(rect: rect, into: &window)

        if isFocused {
            guard let frame = global.intersection(rect) else { return }
            for i in frame.indices {
                window[i]?.attributes.inverted = true
            }
        }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        visitor.visit(focus: focusableElement)
    }

    override var description: String {
        "Button\(isFocused ? " FOCUSED" : "")"
    }

    override func hitTest(at position: Position, key: Key) -> (any Control)? {
        guard global.contains(position) else { return nil }
        if case .mouseUp = key.value, !isFocused {
            root?.focusManager?.change(focus: focusableElement)
        }
        return self
    }
}

extension ButtonNode: Focusable {
    func becomeFirstResponder() {
        isFocused = true
    }

    func resignFirstResponder() {
        isFocused = false
    }

    var isFocusable: Bool { !resolvedEnvironment().isDisabled }

    func handle(key: Key) -> Bool {
        guard !resolvedEnvironment().isDisabled else { return false }
        switch key.value {
        case .space, .enter, .mouseUp(button: 0, at: _):
            action()
            return true
        default: return false
        }
    }
}
