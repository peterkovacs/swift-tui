extension View {
    public func frame(width: Extended? = nil, height: Extended? = nil, alignment: Alignment = .center) -> some View {
        FixedFrame(
            width: width,
            height: height,
            alignment: alignment,
            content: self
        )
    }
}

struct FixedFrame<Content: View>: View, PrimitiveView {
    var width, height: Extended?
    var alignment: Alignment
    let content: Content

    func build(parent: Node?) -> Node {
        let node = FixedFrameNode(
            view: self,
            parent: parent,
            content: self,
            width: width,
            height: height,
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
        node.width = width
        node.height = height
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FixedFrameNode: ModifierNode {
    var width, height: Extended?
    var alignment: Alignment

    init<Content: View>(view: any GenericView, parent: Node?, content: Content, width: Extended?, height: Extended?, alignment: Alignment) {
        self.width = width
        self.height = height
        self.alignment = alignment
        super.init(view: view, parent: parent, content: content)
    }

    private func aligned(rect childSize: Size, bounds: Size) -> Position {
        var result = Position.zero
        let size = size(child: childSize, bounds: bounds)

        switch alignment.horizontalAlignment {
        case .leading:
            result.column = 0
        case .center:
            result.column += (size.width - childSize.width) / 2
        case .trailing:
            result.column += (size.width - childSize.width)
        }

        switch alignment.verticalAlignment {
        case .top:
            result.line = 0
        case .center:
            result.line += (size.height - childSize.height) / 2
        case .bottom:
            result.line += (size.height - childSize.height)
        }

        return result
    }

    private func size(child childSize: Size, bounds: Size) -> Size {
        let width = if width == .infinity {
            max(childSize.width, bounds.width)
        } else if let width {
            min(width, childSize.width)
        } else {
            childSize.width
        }

        let height = if height == .infinity {
            max(childSize.height, bounds.height)
        } else if let height {
            min(height, childSize.height)
        } else {
            childSize.height
        }

        return Size(width: width, height: height)
    }

    private func global(_ childFrame: Rect, bounds: Size) -> Rect {
        .init(
            position: childFrame.position - aligned(rect: childFrame.size, bounds: bounds),
            size: size(child: childFrame.size, bounds: bounds)
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
                    frame = frame.union(.init(position: .zero, size: rect.size))

                    let childFrame = element.layout(.init(position: .zero, size: rect.size))
                    let alignment = aligned(rect: childFrame.size, bounds: rect.size)

                    return .init(
                        position: element.frame(
                            childFrame + rect.position + alignment
                        ).position - alignment,
                        size: size(child: childFrame.size, bounds: rect.size)
                    )
                } global: { [weak self] in
                    guard let self else { return .zero }
                    return global(element.global(), bounds: frame.size)
                }
            )
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        for element in sizeVisitor.visited {
            visitor.visit(
                size: .init(node: element.node) { [weak self] proposedSize in
                    guard let self else { return .zero }
                    return size(child: element.size(proposedSize), bounds: proposedSize)
                }
            )
        }
    }

    override var description: String {
        let width = width.map { "\($0)" } ?? "(nil)"
        let height = height.map { "\($0)" } ?? "(nil)"

        return "FixedFrame:\(width)x\(height) \(layoutVisitor.visited.map { global($0.global(), bounds: frame.size) })"
    }
}
