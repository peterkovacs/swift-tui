extension View {
    public func frame(width: Extended = .infinity, height: Extended = .infinity, alignment: Alignment = .center) -> some View {
        FixedFrame(
            size: .init(width: width, height: height),
            alignment: alignment,
            content: self
        )
    }
}

struct FixedFrame<Content: View>: View, PrimitiveView {
    var size: Size
    var alignment: Alignment
    let content: Content

    func build(parent: Node?) -> Node {
        let node = FixedFrameNode(
            view: self,
            parent: parent,
            content: self,
            size: size,
            alignment: alignment
        )

        node.add(at: 0, node: content.view.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let node = node as? FixedFrameNode else {
            fatalError("Invalid node type")
        }

        node.view = self
        node.set(references: self)
        node.size = size
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FixedFrameNode: ModifierNode {
    var size: Size
    var alignment: Alignment

    init<Content: View>(view: any GenericView, parent: Node?, content: Content, size: Size, alignment: Alignment) {
        self.size = size
        self.alignment = alignment
        super.init(view: view, parent: parent, content: content)
    }

    private func aligned(rect childFrame: Rect) -> Position {
        var result = Position.zero
        let size = size.clamped(to: childFrame.size)

        switch alignment.horizontalAlignment {
        case .leading:
            result.column = 0
        case .center:
            result.column += (size.width - childFrame.size.width) / 2
        case .trailing:
            result.column += (size.width - childFrame.size.width)
        }

        switch alignment.verticalAlignment {
        case .top:
            result.line = 0
        case .center:
            result.line += (size.height - childFrame.size.height) / 2
        case .bottom:
            result.line += (size.height - childFrame.size.height)
        }

        return result
    }

    private func global(_ childFrame: Rect) -> Rect {
        .init(
            position: childFrame.position - aligned(rect: childFrame),
            size: size.clamped(to: childFrame.size)
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        // TODO: deal with alignment...

        for element in layoutVisitor.visited {
            visitor.visit(
                layout: .init(
                    node: element.node
                ) { (rect: Rect) in
                    return rect.clamped(to: element.layout(rect))
                } frame: { [weak self] rect in
                    guard let self else { return .zero }

                    let childFrame = element.layout(.init(position: .zero, size: rect.size))
                    let alignment = aligned(rect: childFrame)

                    return .init(
                        position: element.frame(
                            childFrame + rect.position + alignment
                        ).position - alignment,
                        size: size
                    )
                } global: { [weak self] in
                    guard let self else { return .zero }
                    return global(element.global())
                }
            )
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        for element in sizeVisitor.visited {
            visitor.visit(
                size: .init(node: element.node) { [size] proposedSize in
                    size.clamped(to: element.size(proposedSize))
                }
            )
        }
    }

    override var description: String {
        "FixedFrame:\(size) \(layoutVisitor.visited.map { global($0.global()) })"
    }
}
