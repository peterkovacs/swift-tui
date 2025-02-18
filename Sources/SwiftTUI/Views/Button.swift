import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let action: @MainActor () -> Void
    let label: Label

    public init(action: @escaping @MainActor () -> Void, label: () -> Label) {
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

    func build(parent: Node?) -> Node {
        let node = ButtonNode(
            view: self,
            parent: parent,
            action: action
        )

        node.add(at: 0, node: label.view.build(parent: node))
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
    var isFocused: Bool

    init(view: any GenericView, parent: Node?, action: @escaping @MainActor () -> Void) {
        self.action = action
        self.isFocused = false
        super.init(view: view, parent: parent, alignment: .center, spacing: 1)
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        super.draw(rect: rect, into: &window)
        
        if isFocused {
            for i in rect.indices {
                window[i]?.attributes.inverted = true
            }
        }
    }
}

extension ButtonNode: Focusable {
    func becomeFirstResponder() {
        isFocused = true
    }

    func resignFirstResponder() {
        isFocused = false
    }

    var isFocusable: Bool { true }

    func handle(key: Key) -> Bool {
        switch key {
        case .init(.space), .init(.enter):
            action()
            return true
        default: return false
        }
    }
}
