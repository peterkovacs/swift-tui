/// A node that modifies Controls lower in the hierarchy. E.g. BorderNode, PaddingNode.
///
class ModifierNode: ComposedNode {

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
        guard let _layoutVisitor else {
            let visitor = LayoutVisitor(children: children) { $0.layout(visitor: &$1) }
            _layoutVisitor = visitor
            return visitor
        }

        return _layoutVisitor
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
        var visited: [Visitor.LayoutElement]

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
            visited.append(layout)
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        super.size(visitor: &visitor)
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        super.layout(visitor: &visitor)
    }

    override func invalidateLayout() {
        _sizeVisitor = nil
        _layoutVisitor = nil
        super.invalidateLayout()
    }
}

