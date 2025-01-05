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

class TextNode: Node, Control {
    var text: Text.Value

    init(view: any GenericView, parent: Node?, text: Text.Value) {
        self.text = text
        super.init(view: view, parent: parent)
    }

    override func size<T>(visitor: inout T) where T : SizeVisitor {
        visitor.visit(node: self, size: size)
    }

    func size(proposedSize: Size) -> Size {
        switch text {
        case .string(let string):
            // TODO: handle multi-line and proposedSize that spills our text onto multiple lines.
            return .init(width: Extended(string.count), height: 1)
            
        case .attributed(let attributed):
            // TODO: Deal with attributed
            return proposedSize

            // return .init(width: String(attributed).count, height: attributed.exported.height)
        }
    }
}
