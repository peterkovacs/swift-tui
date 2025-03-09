
public struct VStack<Content: View>: View, PrimitiveView {
    let alignment: HorizontalAlignment
    let spacing: Extended
    let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Extended = 0,
        @ViewBuilder _ content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = VStackNode(
            view: self.view,
            parent: parent,
            root: root,
            alignment: alignment,
            spacing: spacing
        )

        node.add(at: 0, node: content.view.build(parent: node, root: root))
        return node
    }

    func update(node: Node) {
        guard let node = node as? VStackNode else { fatalError() }
        node.view = self
        node.alignment = alignment
        node.spacing = spacing

        node.children[0].update(view: content.view)
    }
}

/// A Vertical Stack Control with an alignment and spacing.
class VStackNode: Node, Control {
    var alignment: HorizontalAlignment { didSet { if alignment != oldValue { invalidateLayout() } } }
    var spacing: Extended { didSet { if spacing != oldValue { invalidateLayout() } } }

    fileprivate var _sizeVisitor: SizeVisitor? = nil
    var sizeVisitor: SizeVisitor {
        get {
            let visitor = _sizeVisitor ?? SizeVisitor(spacing: spacing, children: children)
            _sizeVisitor = visitor
            return visitor
        }

        set {
            _sizeVisitor = newValue
        }
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

    override init<T: View>(root view: T) {
        self.alignment = .center
        self.spacing = 0
        super.init(root: view)
    }

    init(
        view: any GenericView,
        parent: Node?,
        root: RootNode?,
        alignment: HorizontalAlignment,
        spacing: Extended
    ) {
        self.alignment = alignment
        self.spacing = spacing
        super.init(view: view, parent: parent, root: root)
        self.environment = {
            $0.layoutAxis = .vertical
        }
    }

    struct SizeVisitor: Visitor.Size {
        let spacing: Extended
        var visited: [Visitor.SizeElement]
        var cache: [Size: Size]


        fileprivate init(spacing: Extended, children: [Node]) {
            self.spacing = spacing
            self.visited = []
            self.cache = [:]

            for child in children {
                child.size(visitor: &self)
            }
        }

        mutating func visit(size: Visitor.SizeElement) {
            visited.append(size)
        }

        mutating func size(proposedSize: Size) -> Size {
            if let cached = cache[proposedSize] {
                return cached
            }

            let children = visited
                .map { (size: $0.size, flexibility: $0.verticalFlexibility(proposedSize.width)) }
                .sorted { $0.flexibility < $1.flexibility }

            // Anything that is infinitely flexible does not get spacing before it
            var resultSize: Size = .init(
                width: 0,
                height: Extended(children.filter { $0.flexibility != .infinity }.count - 1) * spacing
            )

            var remaining = children.count

            for (size, _) in children {
                // How much height is remaining based on what's used so far.
                let remainingHeight = resultSize.height == .infinity ? .infinity : proposedSize.height - resultSize.height

                // How much does this child use.
                let childSize = size(
                    Size(
                        width: proposedSize.width,
                        height: remainingHeight / Extended(remaining)
                    )
                )

                resultSize.height += childSize.height
                resultSize.width = max(resultSize.width, childSize.width)
                remaining -= 1
            }

            cache[proposedSize] = resultSize
            return resultSize
        }
    }

    struct LayoutVisitor: Visitor.Layout {
        let spacing: Extended
        let alignment: HorizontalAlignment
        var visited: [(element: Visitor.LayoutElement, frame: Rect)]
        var cache: [Rect: Rect]

        fileprivate init(spacing: Extended, alignment: HorizontalAlignment, children: [Node]) {
            self.spacing = spacing
            self.alignment = alignment
            self.visited = []
            self.cache = [:]
            for child in children {
                child.layout(visitor: &self)
            }
        }

        mutating func visit(layout: Visitor.LayoutElement) {
            visited.append((layout, layout.node.frame))
        }

        mutating func layout(rect: Rect) -> Rect {
            if let cache = cache[rect] { return cache }

            let childrenOrder = visited
                .indices
                .sorted {
                    visited[$0].element.verticalFlexibility(rect.size.width) < visited[$1].element.verticalFlexibility(rect.size.width)
                }

            var remaining = childrenOrder.count
            var frame: Rect = .init(
                position: rect.position,
                size: .init(width: rect.size.width, height: 0)
            )

            // First calculate the sizes of each visited control from least flexible -> most flexible.
            for i in childrenOrder {
                visited[i].frame = visited[i].element.layout(
                    Rect(
                        // Children are laid out relative to _this_ frame. Positions should be based on 0.
                        position: .zero,
                        size: Size(
                            width: rect.size.width,
                            height: (rect.size.height - frame.size.height) / Extended(remaining)
                        )
                    )
                )

                frame.size.height += visited[i].frame.size.height
                if visited[i].frame.size.height > 0, remaining > 1 {
                    frame.size.height += spacing
                }
                remaining -= 1
            }

            var line: Extended = 0

            // Next, set the position of each visited control based on the order in which they were defined
            for (element, childFrame) in visited {
                var position: Position = .init(
                    column: 0,
                    line: line
                )

                switch alignment {
                case .leading:  position.column = rect.minColumn
                case .center:   position.column = (rect.size.width - childFrame.size.width) / 2
                case .trailing: position.column = (rect.size.width - childFrame.size.width)
                }

                element.adjust(position)

                if childFrame.size.height > 0 {
                    line += childFrame.size.height
                    line += spacing
                }
            }

            cache[rect] = frame
            return frame
        }
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
                size: self.sizeVisitor.size(
                    proposedSize: rect.size
                )
            )
        )

        return frame
    }

    func size(proposedSize: Size) -> Size {
        self.sizeVisitor.size(proposedSize: proposedSize)
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}
