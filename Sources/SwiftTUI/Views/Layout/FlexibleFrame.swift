extension View {
    public func frame(
        minWidth: Extended? = nil,
        maxWidth: Extended? = nil,
        minHeight: Extended? = nil,
        maxHeight: Extended? = nil,
        alignment: Alignment = .center
    ) -> some View {
        FlexibleFrame(
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            alignment: alignment,
            content: self
        )
    }
}

struct FlexibleFrame<Content: View>: View, PrimitiveView {
    var minWidth: Extended? = nil
    var maxWidth: Extended? = nil
    var minHeight: Extended? = nil
    var maxHeight: Extended? = nil
    var alignment: Alignment
    let content: Content

    func build(parent: Node?) -> Node {
        let node = FlexibleFrameNode(
            view: self,
            parent: parent,
            content: self,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
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
        node.minWidth = minWidth
        node.maxWidth = maxWidth
        node.minHeight = minHeight
        node.maxHeight = maxHeight
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FlexibleFrameNode: ModifierNode {
    var minWidth: Extended? = nil
    var maxWidth: Extended? = nil
    var minHeight: Extended? = nil
    var maxHeight: Extended? = nil
    var alignment: Alignment

    init<Content: View>(
        view: any GenericView,
        parent: Node?,
        content: Content,
        minWidth: Extended?,
        maxWidth: Extended?,
        minHeight: Extended?,
        maxHeight: Extended?,
        alignment: Alignment
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
        super.init(view: view, parent: parent, content: content)
    }

    private func size(child childSize: Size, bounds: Size) -> Size {
        let minWidth =
            minWidth != nil ? max(minWidth ?? childSize.width, childSize.width) : childSize.width

        let maxWidth = maxWidth == .infinity ? max( childSize.width, bounds.width ) :
            maxWidth != nil ? min(maxWidth ?? childSize.width, childSize.width) : childSize.width

        let minHeight =
            minHeight != nil ? max(minHeight ?? childSize.height, childSize.height) : childSize.height

        let maxHeight = maxHeight == .infinity ? max( childSize.height, bounds.height ) :
            maxHeight != nil ? min(maxHeight ?? childSize.height, childSize.height) : childSize.height

        precondition(minWidth > 0 && maxWidth > 0 && minHeight > 0 && maxHeight > 0)

        let minSize = Size(width: minWidth, height: minHeight) // .clamped(to: childSize.clamped(to: bounds))
        let maxSize = Size(width: maxWidth, height: maxHeight) // .clamped(to: childSize.clamped(to: bounds))

        return Size(
            width: minSize.width > childSize.width
                    ? minSize.width
                    : maxSize.width,
            height: minSize.height > childSize.height
                    ? minSize.height
                    : maxSize.height
        )
    }

    private func aligned(rect childFrame: Rect, bounds: Size) -> Position {
        var result = Position.zero
        let size = size(child: childFrame.size, bounds: bounds)

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

    private func global(_ childFrame: Rect, bounds: Size) -> Rect {
        .init(
            position: childFrame.position - aligned(rect: childFrame, bounds: bounds),
            size: size(child: childFrame.size, bounds: bounds)
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        for element in layoutVisitor.visited {
            visitor.visit(
                layout: .init(
                    node: element.node
                ) { [weak self] (rect: Rect) in
                    guard let self else { return .zero }

                    // This is called to determine the size of the frame. it needs to actually be smarter than just a `clamped`.
                    return .init(
                        position: rect.position,
                        size: size(child: element.layout(rect).size, bounds: rect.size)
                    )
                    // return rect.clamped(to: element.layout(rect))
                } frame: { [weak self] rect in
                    // The rect here is now the correct bounds.
                    guard let self else { return .zero }
                    frame = frame.union(.init(position: .zero, size: rect.size))

                    let childFrame = element.layout(.init(position: .zero, size: rect.size))
                    let alignment = aligned(rect: childFrame, bounds: rect.size)

                    // This returns the correct size based on the flexible (potentially infinite) layout.
                    // However, its actually setting a potentially much smaller frame on the contained control.
                    //
 
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
            // We only want to send the visitor for things that aren't infinitely sized
            if
                (maxWidth == .infinity && element.node.size(proposedSize: .init(width: .infinity, height: 0)).width == .infinity) ||
                (maxHeight == .infinity && element.node.size(proposedSize: .init(width: 0, height: .infinity)).height == .infinity)
            {
                visitor.visit(
                    size: .init(node: element.node) {  proposedSize in
                        return element.size(proposedSize)
                    }
                )
            }

            visitor.visit(
                size: .init(node: element.node) { [weak self] proposedSize in
                    guard let self else { return .zero }
                    return size(child: element.size(proposedSize), bounds: proposedSize)
                }
            )
        }
    }

    override var description: String {
        let minWidth = minWidth.map { "\($0)" } ?? "(nil)"
        let minHeight = minHeight.map { "\($0)" } ?? "(nil)"
        let maxWidth = maxWidth.map { "\($0)" } ?? "(nil)"
        let maxHeight = maxHeight.map { "\($0)" } ?? "(nil)"
        return  "FlexibleFrame:\(minWidth)x\(minHeight)/\(maxWidth)x\(maxHeight) \(layoutVisitor.visited.map { global($0.global(), bounds: frame.size) })"
    }
}
