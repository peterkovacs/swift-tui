
public enum VerticalAlignment: Sendable, Hashable {
    case top
    case center
    case bottom
}

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

    fileprivate var _layoutVisitor: Layout? = nil
    var layoutVisitor: Layout {
        let visitor = _layoutVisitor ?? Layout(
            spacing: spacing,
            alignment: alignment,
            children: children
        )
        _layoutVisitor = visitor
        return visitor
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
    }

    struct SizeVisitor: SwiftTUI.LayoutVisitor {
        let spacing: Extended
        var visited: [(node: Control, size: (Size) -> Size)]

        fileprivate init(spacing: Extended, children: [Node]) {
            self.spacing = spacing
            self.visited = []
            for child in children {
                child.size(visitor: &self)
            }
        }

        static var axis: Axis { .horizontal }

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
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

    struct Layout: LayoutVisitor {
        let spacing: Extended
        let alignment: VerticalAlignment
        var visited: [(node: Control, layout: (Size) -> Size)]

        fileprivate init(spacing: Extended, alignment: VerticalAlignment, children: [Node]) {
            self.spacing = spacing
            self.alignment = alignment
            self.visited = []
            for child in children {
                child.layout(visitor: &self)
            }
        }

        static var axis: Axis { .horizontal }

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }

        func layout(size: Size) -> Size {
            let children = visited
                .sorted { $0.node.horizontalFlexibility(height: size.height) < $1.node.horizontalFlexibility(height: size.height) }
                .map(\.layout)

            var remaining = children.count
            var remainingWidth = size.width

            for (childSize) in children {
                // Calculates *and sets* the frame size based on the `size(proposedSize:)` from the provided size..
                let childSize = childSize(
                    Size(
                        width: remainingWidth / Extended(remaining),
                        height: size.height
                    )
                )

                remainingWidth -= childSize.width
                if childSize.width > 0 {
                    remainingWidth -= spacing
                }
                remaining -= 1
            }

            var column: Extended = 0
            for (control, _) in visited {
                var position = Position(column: column, line: 0)

                if control.frame.size.width > 0 {
                    column += control.frame.size.width
                    column += spacing
                }

                switch alignment {
                case .top: position.line = 0
                case .center: position.line = (size.height - control.frame.size.height) / 2
                case .bottom: position.line = size.height - control.frame.size.height
                }

                // print("moving \(String(describing: control)) to \(position))")
                control.move(to: position)
            }

            return size
        }
    }

    override func size<T>(visitor: inout T) where T : SwiftTUI.LayoutVisitor {
        visitor.visit(node: self, size: self.sizeVisitor.size(proposedSize:))
    }

    override func layout<T>(visitor: inout T) where T : SwiftTUI.LayoutVisitor {
        visitor.visit(node: self) { size in
            super.layout(size: self.layoutVisitor.layout(size: size))
        }
    }

    override func layout(size: Size) -> Size {
        super.layout(size: layoutVisitor.layout(size: self.sizeVisitor.size(proposedSize: size)))
    }

    func size(proposedSize: Size) -> Size {
        self.sizeVisitor.size(proposedSize: proposedSize)
    }
}
