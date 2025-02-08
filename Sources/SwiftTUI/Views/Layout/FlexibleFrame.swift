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
        node.minWidth = minWidth
        node.maxWidth = maxWidth
        node.minHeight = minHeight
        node.maxHeight = maxHeight
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FlexibleFrameNode: Node {
    var minWidth: Extended? = nil { didSet { invalidateLayout() } }
    var maxWidth: Extended? = nil { didSet { invalidateLayout() } }
    var minHeight: Extended? = nil { didSet { invalidateLayout() } }
    var maxHeight: Extended? = nil { didSet { invalidateLayout() } }
    var alignment: Alignment { didSet { invalidateLayout() } }

    var _sizeVisitor: SizeVisitor? = nil
    var sizeVisitor: SizeVisitor {
        guard let _sizeVisitor else {
            let visitor = SizeVisitor(children: children) { $0.size(visitor: &$1) }
            _sizeVisitor = visitor
            return visitor
        }

        return _sizeVisitor
    }

    var _layoutVisitor: LayoutVisitor? = nil
    var layoutVisitor: LayoutVisitor {
        _read {
            _layoutVisitor = _layoutVisitor ?? LayoutVisitor(children: children) { $0.layout(visitor: &$1) }
            yield _layoutVisitor!
        }

        _modify {
            _layoutVisitor = _layoutVisitor ?? LayoutVisitor(children: children) { $0.layout(visitor: &$1) }
            yield &_layoutVisitor!
        }
    }

    struct SizeVisitor: Visitor.Size {
        var visited: [Visitor.SizeElement]

        fileprivate init(
            children: [Node],
            action: (Node, inout Self) -> Void
        ) {
            self.visited = []

            for child in children {
                action(child, &self)
            }
        }

        mutating func visit(size: Visitor.SizeElement) {
            visited.append(size)
        }
    }

    struct LayoutVisitor: Visitor.Layout {
        var visited: [(element: Visitor.LayoutElement, size: Size)]

        fileprivate init(
            children: [Node],
            action: (Node, inout Self) -> Void
        ) {
            self.visited = []

            for child in children {
                action(child, &self)
            }
        }

        mutating func visit(layout: Visitor.LayoutElement) {
            visited.append((layout, .zero))
        }
    }


    init(
        view: any GenericView,
        parent: Node?,
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
        super.init(view: view, parent: parent)
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

    private func aligned(rect childFrame: Size, bounds: Size) -> Position {
        var result = Position.zero
        let size = size(child: childFrame, bounds: bounds)

        switch alignment.horizontalAlignment {
        case .leading:
            result.column = 0
        case .center:
            result.column += (size.width - childFrame.width) / 2
        case .trailing:
            result.column += (size.width - childFrame.width)
        }

        switch alignment.verticalAlignment {
        case .top:
            result.line = 0
        case .center:
            result.line += (size.height - childFrame.height) / 2
        case .bottom:
            result.line += (size.height - childFrame.height)
        }

        return result
    }

    private func global(_ childFrame: Rect, bounds: Size) -> Rect {
        .init(
            position: childFrame.position - aligned(rect: childFrame.size, bounds: bounds),
            size: size(child: childFrame.size, bounds: bounds)
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        for i in layoutVisitor.visited.indices {
            let (element, _) = layoutVisitor.visited[i]

            visitor.visit(
                layout: .init(
                    node: element.node
                ) { [weak self] (rect: Rect) in
                    guard let self else { return .zero }

                    // - call layout on the control
                    // - calculate the alignment and set using `adjust`
                    // - store the calculated bounds for this control so that we can refer to it in `global`.
                    // - return the full width of the frame so that the layout in which this fixedFrame appears is calculated correctly.

                    let childFrame = element.layout(rect)
                    let bounds = size(child: childFrame.size, bounds: rect.size)
                    let alignment = aligned(rect: childFrame.size, bounds: bounds)

                    element.adjust(alignment)
                    layoutVisitor.visited[i].size = bounds

                    return .init(
                        position: rect.position,
                        size: bounds
                    )
                } adjust: { position in
                    element.adjust(position)
                } global: { [weak self] in
                    guard let self else { return .zero }
                    return global(element.global(), bounds: layoutVisitor.visited[i].size)
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
        return  "FlexibleFrame:\(minWidth)x\(minHeight)/\(maxWidth)x\(maxHeight) \(layoutVisitor.visited.map(\.size))"
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}
