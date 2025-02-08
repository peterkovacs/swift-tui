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
        node.width = width
        node.height = height
        node.alignment = alignment

        node.children[0].update(view: content.view)
    }
}

final class FixedFrameNode: Node {
    var width: Extended? { didSet { invalidateLayout() } }
    var height: Extended? { didSet { invalidateLayout() } }
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

    init(view: any GenericView, parent: Node?, width: Extended?, height: Extended?, alignment: Alignment) {
        self.width = width
        self.height = height
        self.alignment = alignment
        super.init(view: view, parent: parent)
    }

    private func size(child childSize: Size, bounds: Size) -> Size {
        let width = if let width {
            width.clamped(to: childSize.width)
        } else {
            childSize.width
        }

        let height = if let height {
            height.clamped(to: childSize.height)
        } else {
            childSize.height
        }

        return Size(width: width, height: height)
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
                layout: .init(node: element.node) { [weak self] rect in
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

        return "FixedFrame:\(width)x\(height) \(layoutVisitor.visited.map(\.size))"
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}
