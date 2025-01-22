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

class ZStackNode: Node, Control {
    var alignment: Alignment

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

        fileprivate init(children: [Node]) {
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
                $0.expand(to: $1.size($0))
            }
        }
    }

    struct LayoutVisitor: Visitor.Layout {
        let alignment: Alignment
        var visited: [Visitor.LayoutElement]
        var calculatedLayout: (Rect, Rect)?

        fileprivate init(alignment: Alignment, children: [Node]) {
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

            var result = Rect.zero

            for element in visited {
                var frame = element.layout(rect)

                switch alignment.horizontalAlignment {
                case .leading:  frame.position.column = 0
                case .center:   frame.position.column = (rect.size.width - frame.size.width) / 2
                case .trailing: frame.position.column = (rect.size.width - frame.size.width)
                }

                switch alignment.verticalAlignment {
                case .top:    frame.position.line = 0
                case .center: frame.position.line = (rect.size.height - frame.size.height) / 2
                case .bottom: frame.position.line = (rect.size.height - frame.size.height)
                }

                result = result.union(element.frame(frame))
            }

            calculatedLayout = (rect, result)
            return result
        }
    }

    func size(proposedSize: Size) -> Size {
        sizeVisitor.size(proposedSize: proposedSize)
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: .init(node: self, size: self.sizeVisitor.size(proposedSize:)))
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self) { rect in
                super.layout(
                    rect:
                        self.layoutVisitor.layout(
                            rect: .init(
                                position: rect.position,
                                size: self.sizeVisitor.size(
                                    proposedSize: rect.size
                                )
                            )
                        )
                )
            } frame: {
                self.frame = $0
                return $0
            } global: {
                self.global
            }
        )
    }

    override func layout(rect: Rect) -> Rect {
        super.layout(
            rect: layoutVisitor.layout(
                rect: .init(
                    position: rect.position,
                    size: sizeVisitor.size(proposedSize: rect.size)
                )
            )
        )
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}
