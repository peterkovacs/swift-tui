
public enum HorizontalAlignment: Sendable, Hashable {
    case leading
    case center
    case trailing
}

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

    func build(parent: Node?) -> Node {
        let node = VStackNode(
            view: self.view,
            parent: parent,
            alignment: alignment,
            spacing: spacing
        )

        node.add(at: 0, node: content.view.build(parent: node))
        return node
    }

    func update(node: Node) {
        guard let node = node as? VStackNode else { fatalError() }
        node.view = self
        node.children[0].update(view: content.view)
        node.alignment = alignment
        node.spacing = spacing
        node._sizeVisitor = nil
    }
}

final class VStackNode: Node, Control {
    var alignment: HorizontalAlignment
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

    init<T: View>(
        root view: T,
        application: Application?
    ) {
        self.alignment = .center
        self.spacing = 0
        super.init(
            root: VStack { view }.view,
            application: application
        )

        add(at: 0, node: view.view.build(parent: self))
    }

    init(
        view: any GenericView,
        parent: Node?,
        alignment: HorizontalAlignment,
        spacing: Extended
    ) {
        self.alignment = alignment
        self.spacing = spacing
        super.init(view: view, parent: parent)
    }

    struct SizeVisitor: LayoutVisitor {
        let spacing: Extended
        var visited: [(node: Control, size: (Size) -> Size)]

        fileprivate init(spacing: Extended, children: [Node]) {
            self.spacing = spacing
            self.visited = []
            for child in children {
                child.size(visitor: &self)
            }
        }

        static var axis: Axis { .vertical }

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }

        func size(proposedSize: Size) -> Size {
            let children = visited
                .map { (size: $0.size, flexibility: $0.node.verticalFlexibility(width: proposedSize.width)) }
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

            return resultSize
        }
    }

    struct Layout: LayoutVisitor {
        let spacing: Extended
        let alignment: HorizontalAlignment
        var visited: [(node: Control, layout: (Size) -> Size)]

        fileprivate init(spacing: Extended, alignment: HorizontalAlignment, children: [Node]) {
            self.spacing = spacing
            self.alignment = alignment
            self.visited = []
            for child in children {
                child.layout(visitor: &self)
            }
        }

        static var axis: Axis { .vertical }

        mutating func visit(node: Control, size: @escaping (Size) -> Size) {
            visited.append((node, size))
        }

        func layout(size: Size) -> Size {
            let children = visited
                .sorted { $0.node.verticalFlexibility(width: size.width) < $1.node.verticalFlexibility(width: size.width) }
                .map(\.layout)

            var remaining = children.count
            var remainingHeight = size.height

            for (childSize) in children {
                // Calculates *and sets* the frame size based on the `size(proposedSize:)` from the provided size..
                let childSize = childSize(
                    Size(
                        width: size.width,
                        height: remainingHeight / Extended(remaining)
                    )
                )

                remainingHeight -= childSize.height
                if childSize.height > 0 {
                    remainingHeight -= spacing
                }
                remaining -= 1
            }


            var line: Extended = 0

            for (control, _) in visited {
                var position = Position(column: 0, line: line)

                if control.frame.size.height > 0 {
                    line += control.frame.size.height
                    line += spacing
                }

                switch alignment {
                case .leading: position.column = 0
                case .center: position.column = (size.width - control.frame.size.width) / 2
                case .trailing: position.column = size.width - control.frame.size.width
                }

                control.move(to: position)
            }

            return size
        }
    }

    override func size<T>(visitor: inout T) where T : LayoutVisitor {
        visitor.visit(node: self, size: self.sizeVisitor.size(proposedSize:))
    }

    override func layout<T>(visitor: inout T) where T : SwiftTUI.LayoutVisitor {
        visitor.visit(node: self) { size in
            super.layout(size: self.layoutVisitor.layout(size: self.sizeVisitor.size(proposedSize: size)))
        }
    }

    override func layout(size: Size) -> Size {
        super.layout(size: layoutVisitor.layout(size: self.sizeVisitor.size(proposedSize: size)))
    }

    func size(proposedSize: Size) -> Size {
        self.sizeVisitor.size(proposedSize: proposedSize)
    }
}
