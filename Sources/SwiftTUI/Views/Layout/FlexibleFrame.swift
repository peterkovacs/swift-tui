extension View {
    public func frame(
        minWidth: Extended = .negativeInfinity,
        maxWidth: Extended = .infinity,
        minHeight: Extended = .negativeInfinity,
        maxHeight: Extended = .infinity,
        alignment: Alignment = .center
    ) -> some View {
        FlexibleFrame(
            minSize: .init(width: minWidth, height: minHeight),
            maxSize: .init(width: maxWidth, height: maxHeight),
            alignment: alignment,
            content: self
        )
    }
}

struct FlexibleFrame<Content: View>: View, PrimitiveView {
    var minSize: Size
    var maxSize: Size
    var alignment: Alignment
    let content: Content

    func build(parent: Node?) -> Node {
        let node = FlexibleFrameNode(
            view: self,
            parent: parent,
            content: self,
            minSize: minSize,
            maxSize: maxSize,
            alignment: alignment
        )

        node.add(at: 0, node: content.view.build(parent: node))

        return node
    }

    func update(node: Node) {
        guard let node = node as? FlexibleFrameNode else {
            fatalError("Invalid node type")
        }

        node.view = self
        node.set(references: self)
        node.minSize = minSize
        node.maxSize = maxSize
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FlexibleFrameNode: ModifierNode {
    var minSize: Size
    var maxSize: Size
    var alignment: Alignment

    init<Content: View>(view: any GenericView, parent: Node?, content: Content, minSize: Size, maxSize: Size, alignment: Alignment) {
        self.minSize = minSize
        self.maxSize = maxSize
        self.alignment = alignment
        super.init(view: view, parent: parent, content: content)
    }

    private func size(child childSize: Size) -> Size {
        let minSize = minSize.clamped(to: childSize)
        let maxSize = maxSize.clamped(to: childSize)
        return Size(
            width: minSize.width > childSize.width
                    ? minSize.width
                    : maxSize.width < childSize.width
                        ? maxSize.width
                        : childSize.width,
            height: minSize.height > childSize.height
                    ? minSize.height
                    : maxSize.height < childSize.height
                        ? maxSize.height
                        : childSize.height
        )
    }

    private func aligned(rect childFrame: Rect) -> Position {
        var result = Position.zero
        let size = size(child: childFrame.size)

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
            size: size(child: childFrame.size)
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
                        size: size(child: childFrame.size)
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
                size: .init(node: element.node) { [weak self] proposedSize in
                    guard let self else { return .zero }
                    return size(child: element.size(proposedSize))
                }
            )
        }
    }

    override var description: String {
        "FlexibleFrame:\(minSize)/\(maxSize) \(layoutVisitor.visited.map { global($0.global()) })"
    }
}
