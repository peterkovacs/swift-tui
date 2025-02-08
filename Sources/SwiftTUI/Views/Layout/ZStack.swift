public struct ZStack<Content: View>: View, PrimitiveView {
    let content: Content
    let alignment: Alignment

    public init(
        alignment: Alignment = .center,
        @ViewBuilder _ content: () -> Content
    ) {
        self.content = content()
        self.alignment = alignment
    }

    func build(parent: Node?) -> Node {
        let node = ZStackNode(
            view: view,
            parent: parent,
            alignment: alignment
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? ZStackNode else { fatalError() }
        node.alignment = alignment
        node.children[0].update(view: content.view)
    }
}

final class ZStackNode: Node, Control {
    var alignment: Alignment {
        didSet {
            invalidateLayout()
        }
    }

    fileprivate var _sizeVisitor: SizeVisitor? = nil
    var sizeVisitor: SizeVisitor {
        let visitor = _sizeVisitor ?? SizeVisitor(children: children)
        _sizeVisitor = visitor
        return visitor
    }

    fileprivate var _layoutVisitor: LayoutVisitor? = nil
    var layoutVisitor: LayoutVisitor {
        get {
            let visitor = _layoutVisitor ?? LayoutVisitor(
                alignment: alignment,
                children: children
            )
            _layoutVisitor = visitor
            return visitor
        }
        set {
            _layoutVisitor = newValue
        }
    }

    init(
        view: any GenericView,
        parent: Node?,
        alignment: Alignment
    ) {
        self.alignment = alignment
        super.init(view: view, parent: parent)
        self.environment = { $0.layoutAxis = .none }
    }

    struct SizeVisitor: Visitor.Size {
        var visited: [Visitor.SizeElement]

        init(children: [Node]) {
            self.visited = []
            for child in children {
                child.size(visitor: &self)
            }
        }

        mutating func visit(size: Visitor.SizeElement) {
            visited.append(size)
        }

        func size(proposedSize: Size) -> Size {
            return visited.reduce(into: Size.zero) {
                $0.expand(to: $1.size(proposedSize))
            }
        }
    }

    struct LayoutVisitor: Visitor.Layout {
        let alignment: Alignment
        var visited: [Visitor.LayoutElement]
        var calculatedLayout: (Rect, Rect)?

        init(alignment: Alignment, children: [Node]) {
            self.alignment = alignment
            self.visited = []
            for child in children {
                child.layout(visitor: &self)
            }
        }

        mutating func visit(layout: Visitor.LayoutElement) {
            visited.append(layout)
        }

        mutating func layout(rect: Rect) -> Rect {
            if let (cachedRect, calculatedLayout) = calculatedLayout, cachedRect == rect { return calculatedLayout }

            let result = visited
                .map {
                    ($0.adjust, $0.layout(rect))
                }
                .map { (adjust, frame) in
                    var position = Position.zero

                    switch alignment.horizontalAlignment {
                    case .leading:  position.column = 0
                    case .center:   position.column = (rect.size.width - frame.size.width) / 2
                    case .trailing: position.column = (rect.size.width - frame.size.width)
                    }

                    switch alignment.verticalAlignment {
                    case .top:    position.line = 0
                    case .center: position.line = (rect.size.height - frame.size.height) / 2
                    case .bottom: position.line = (rect.size.height - frame.size.height)
                    }

                    // Align the view in the ZStack
                    adjust(position)

                    return (frame + position)
                }
                .reduce(into: Rect.zero) { $0 = $0.union($1) }


            calculatedLayout = (rect, result)
            return result
        }
    }

    func size(proposedSize: Size) -> Size {
        sizeVisitor.size(proposedSize: proposedSize)
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: sizeElement)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(layout: layoutElement)
    }

    func layout(rect: Rect) -> Rect {
        frame = layoutVisitor.layout(
            rect: .init(
                position: rect.position,
                size: sizeVisitor.size(proposedSize: rect.size)
            )
        )

        return frame
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}
