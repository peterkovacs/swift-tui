
public struct HStack<Content: View>: View, PrimitiveView {
    let alignment: VerticalAlignment
    let spacing: Extended
    let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: Extended = 1,
        @ViewBuilder _ content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = HStackNode(
            view: self.view,
            parent: parent,
            alignment: alignment,
            spacing: spacing
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? HStackNode else { fatalError() }
        node.view = self
        node.children[0].update(view: content.view)
        node.alignment = alignment
        node.spacing = spacing
        node._sizeVisitor = nil
        node._layoutVisitor = nil
    }
}

final class HStackNode: Node, Control {
    var alignment: VerticalAlignment
    var spacing: Extended

    fileprivate var _sizeVisitor: SizeVisitor? = nil
    var sizeVisitor: SizeVisitor {
        let visitor = _sizeVisitor ?? SizeVisitor(spacing: spacing, children: children)
        _sizeVisitor = visitor
        return visitor
    }

    fileprivate var _layoutVisitor: LayoutVisitor? = nil
    var layoutVisitor: LayoutVisitor {
        get {
            let visitor = _layoutVisitor ?? LayoutVisitor(
                spacing: spacing,
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
        alignment: VerticalAlignment,
        spacing: Extended
    ) {
        self.alignment = alignment
        self.spacing = spacing
        super.init(view: view, parent: parent)
        self.environment = {
            $0.layoutAxis = .horizontal
        }
    }

    struct SizeVisitor: Visitor.Size {
        let spacing: Extended
        var visited: [Visitor.SizeElement]

        fileprivate init(spacing: Extended, children: [Node]) {
            self.spacing = spacing
            self.visited = []
            for child in children {
                child.size(visitor: &self)
            }
        }

        mutating func visit(size: Visitor.SizeElement) {
            visited.append(size)
        }

        func size(proposedSize: Size) -> Size {
            let children = visited
                .map { (size: $0.size, flexibility: $0.node.horizontalFlexibility(height: proposedSize.height)) }
                .sorted { $0.flexibility < $1.flexibility }

            var resultSize: Size = .init(
                width: Extended(children.filter { $0.flexibility != .infinity }.count - 1) * spacing,
                height: 0
            )

            var remaining = children.count

            for (size, _) in children {
                // How much height is remaining based on what's used so far.
                let remainingWidth = resultSize.width == .infinity ? .infinity : proposedSize.width - resultSize.width

                // How much does this child use.
                let childSize = size(
                    Size(
                        width: remainingWidth / Extended(remaining),
                        height: proposedSize.height
                    )
                )

                resultSize.height = max(resultSize.height, childSize.height)
                resultSize.width += childSize.width
                remaining -= 1
            }

            return resultSize
        }
    }

    struct LayoutVisitor: Visitor.Layout {
        let spacing: Extended
        let alignment: VerticalAlignment
        var visited: [(element: Visitor.LayoutElement, frame: Rect)]
        var calculatedLayout: Rect?

        fileprivate init(spacing: Extended, alignment: VerticalAlignment, children: [Node]) {
            self.spacing = spacing
            self.alignment = alignment
            self.visited = []
            for child in children {
                child.layout(visitor: &self)
            }
        }

        mutating func visit(layout: Visitor.LayoutElement) {
            visited.append((layout, layout.node.frame))
        }

        mutating func layout(rect: Rect) -> Rect {
            if let calculatedLayout { return calculatedLayout }
            let childrenOrder = visited
                .indices
                .sorted {
                    visited[$0].element.node.horizontalFlexibility(height: rect.size.height) < visited[$1].element.node.horizontalFlexibility(height: rect.size.height)
                }

            var remaining = childrenOrder.count
            var frame: Rect = .init(
                position: rect.position,
                size: .init(width: 0, height: rect.size.height)
            )

            // First calculate the sizes of each visited control from least flexible -> most flexible.
            for i in childrenOrder {
                visited[i].frame = visited[i].element.layout(
                    Rect(
                        position: .zero,
                        size: Size(
                            width: (rect.size.width - frame.size.width) / Extended(remaining),
                            height: rect.size.height
                        )
                    )
                )

                frame.size.width += visited[i].frame.size.width
                if visited[i].frame.size.width > 0, remaining > 1 {
                    frame.size.width += spacing
                }
                remaining -= 1
            }

            var column: Extended = 0

            // Next, set the position of each visited control based on the order in which they were defined
            for (element, var childFrame) in visited {
                childFrame.position.column = column

                switch alignment {
                case .top:    childFrame.position.line = rect.minLine
                case .center: childFrame.position.line = (rect.size.height - childFrame.size.height) / 2
                case .bottom: childFrame.position.line = (rect.size.height - childFrame.size.height)
                }

                childFrame = element.frame( childFrame )

                if childFrame.size.width > 0 {
                    column += childFrame.size.width
                    column += spacing
                }
            }

            calculatedLayout = frame
            return frame
        }
    }


    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(size: .init(node: self, size: self.sizeVisitor.size(proposedSize:)))
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self) { rect in
                super.layout(
                    rect: self.layoutVisitor.layout(
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
                    size: self.sizeVisitor.size(
                        proposedSize: rect.size
                    )
                )
            )
        )
    }

    func size(proposedSize: Size) -> Size {
        self.sizeVisitor.size(proposedSize: proposedSize)
    }
}
