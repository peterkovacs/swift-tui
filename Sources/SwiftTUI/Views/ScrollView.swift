public struct ScrollView<Content: View>: View, PrimitiveView {
    let axes: LayoutAxis.Set
    let content: Content

    public init(_ axes: LayoutAxis.Set = [.vertical], @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = ScrollViewNode(
            view: content,
            parent: parent,
            axes: axes
        )

        // node.focusManager.defaultFocus()
        return node
    }

    func update(node: Node) {
        guard let node = node as? ScrollViewNode else { fatalError() }

        node.axes = axes
        node.children[0].update(view: content.view)
        // TODO: Might need to do something to handle contentOffset changes.
    }
}

class ScrollViewNode: RootNode {
    var axes: LayoutAxis.Set
    var contentOffset: Position = .init(column: 0, line: 0)
    var contentSize: Size = .zero
    var isFocused = false

    var _focusVisitor: FocusVisitor? = nil
    var focusVisitor: FocusVisitor {
        guard let _focusVisitor else {
            let visitor = FocusVisitor(children: children)
            _focusVisitor = visitor
            return visitor
        }

        return _focusVisitor
    }

    struct FocusVisitor: Visitor.Focus {
        var visited: [Visitor.FocusableElement]

        fileprivate init(
            children: [Node]
        ) {
            visited = []
            for child in children {
                child.focus(visitor: &self)
            }
        }

        mutating func visit(focus: Visitor.FocusableElement) {
            visited.append(focus)
        }
    }

    init<T: View>(view: T, parent: Node?, axes: LayoutAxis.Set) {
        self.axes = axes
        super.init(view: view, parent: parent)
    }

    override func invalidate() {
        // The ScrollView itself has been invalidated.
        application?.invalidate(node: self, frame: \.global)
    }

    override func invalidate(node: Node) {
        // A node within the ScrollView has been invalidated.
        // Check to see if it is visible, and if so can invalidate with the application.
        assert(node !== self)

        if isVisible(node.relative(to: self)) {
            application?.invalidate(node: node) { node in
                // must recalculate the frame inside here because the frame may have changed after layout.
                self.global.intersection(node.relative(to: self) - self.contentOffset + self.global.position) ?? .zero
            }
        }
    }

    override func layout(rect: Rect) -> Rect {
        let contentSize = layoutVisitor.layout(
            rect: .init(
                position: .zero,
                size: super.size(
                    proposedSize:  .init(
                        width: axes.contains(.horizontal) ? .infinity : rect.size.width,
                        height: axes.contains(.vertical) ? .infinity : rect.size.height
                    )
                )
            )
        ).size

        frame = .init(
            position: rect.position,
            size: .init(
                width: min(rect.size.width, contentSize.width),
                height: min(rect.size.height, contentSize.height)
            )
        )

//        // TODO: Verify This
//        if rect.size.height + contentOffset.line > contentSize.height {
//            contentOffset.line = contentSize.height - rect.size.height
//        }
//
//        if rect.size.width + contentOffset.column > contentSize.width {
//            contentOffset.column = contentSize.width - rect.size.width
//        }

        return frame
    }

    override func size(proposedSize: Size) -> Size {
        contentSize = super.size(
            proposedSize:  .init(
                width: axes.contains(.horizontal) ? .infinity : proposedSize.width,
                height: axes.contains(.vertical) ? .infinity : proposedSize.height
            )
        )

        // TODO: Handle Scrollbars.
        return .init(
            width: min(contentSize.width, proposedSize.width),
            height: min(contentSize.height, proposedSize.height)
        )
    }

    var hasFocusableElements: Bool {
        focusVisitor.visited.contains { $0.isFocusable() }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        visitor.visit(focus: focusableElement)
//        if hasFocusableElements {
//            for visit in focusVisitor.visited {
//                visitor.visit(
//                    focus: .init(node: visit.node) {
//                        visit.isFocusable()
//                    } handle: { [weak self] key in
//                        self?.handle(key: key) == true || visit.handle(key)
//                    } resignFirstResponder: {
//                        visit.resignFirstResponder()
//                    } becomeFirstResponder: { [weak self] in
//                        self?.scroll(to: visit.node)
//                        visit.becomeFirstResponder()
//                    }
//                )
//            }
//        } else {
//            // If the scoll view has no focusable elements, it is focusable by itself.
//            visitor.visit(focus: focusableElement)
//        }
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        let global = global
        guard let rect = global.intersection(rect) else { return }

        window.with(offset: -contentOffset + global.position) { window in
            children[0].draw(rect: rect + contentOffset - global.position, into: &window)
        }

        // TODO: Scrollbar
    }

    override var description: String {
        "ScrollView [offset:\(contentOffset) size:\(contentSize)]"
    }
}

extension ScrollViewNode: Focusable {
    func becomeFirstResponder() {
        isFocused = true
        if focusManager.focusedElement == nil {
            focusManager?.defaultFocus()
        }
    }
    
    func resignFirstResponder() {
        isFocused = false
        focusManager.focusedElement?.resignFirstResponder()
    }
    
    var isFocusable: Bool {
        true
    }

    func isVisible(_ contentFrame: Rect) -> Bool {
        let viewport = frame + contentOffset

        return !contentFrame.size.isZero && !viewport.size.isZero && viewport.intersection(contentFrame) != nil
    }

    func scroll(to control: any Focusable & Control) {
        // TODO: Animation

        // determine if the control is currently visible on the screen.
        let contentFrame = control.relative(to: self)
        guard !isVisible(contentFrame) else { return }

        var adjustment: Position = .zero
        let viewport = frame + contentOffset

        // minimum change to contentOffset to contain all of contentFrame
        if axes.contains(.vertical) {
            if contentFrame.minLine > viewport.maxLine {
                adjustment.line += contentFrame.minLine - viewport.maxLine + min(frame.size.height, contentFrame.size.height)
            } else if contentFrame.maxLine < viewport.minLine {
                adjustment.line -= viewport.minLine - contentFrame.maxLine + min(frame.size.height, contentFrame.size.height)
            }
        }

        if axes.contains(.horizontal) {
            if contentFrame.minColumn > viewport.maxColumn {
                adjustment.column += (contentFrame.minColumn - viewport.maxColumn) + min(frame.size.width, contentFrame.size.width)
            } else if contentFrame.maxColumn < viewport.minColumn {
                adjustment.column -= viewport.minColumn - contentFrame.maxColumn + min(frame.size.width, contentFrame.size.width)
            }
        }

        contentOffset += adjustment
        invalidate()
    }

    func handle(key: Key) -> Bool {

        if let focusedElement = focusManager.focusedElement, focusManager.handle(key: key) {
            scroll(to: focusedElement.node)
            return true
        }

        switch key {
        case .init(.up):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line > 0  else { return false }

            contentOffset.line -= 1

        case .init(.down):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line + frame.size.height < contentSize.height else { return false }

            contentOffset.line += 1

        case .init(.left):
            guard axes.contains(.horizontal), contentSize.width > frame.size.width else { return false }
            guard contentOffset.column > 0  else { return false }

            contentOffset.column -= 1

        case .init(.right):
            guard axes.contains(.horizontal), contentSize.width > frame.size.width else { return false }
            guard contentOffset.column + frame.size.width < contentSize.width else { return false }

            contentSize.width += 1

        case .init("p", modifiers: .ctrl):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line > 0  else { return false }

            // Move up half a page
            contentOffset.line -= min(frame.size.height / 2, contentOffset.line)

        case .init("n", modifiers: .ctrl):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line + frame.size.height < contentSize.height else { return false }

            // Move down half a page.
            contentOffset.line += min(frame.size.height / 2, contentSize.height - frame.size.height - contentOffset.line)

        case .init(.pageUp):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line > 0 else { return false }

            // Move up a whole page
            contentOffset.line -= min(frame.size.height, contentOffset.line)

        case .init(.pageDown):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line + frame.size.height < contentSize.height else { return false }

            // Move down half a page.
            contentOffset.line += min(frame.size.height, contentSize.height - frame.size.height - contentOffset.line)

        case .init(.home):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line > 0 else { return false }

            contentOffset.line = 0

        case .init(.end):
            guard axes.contains(.vertical), contentSize.height > frame.size.height else { return false }
            guard contentOffset.line + frame.size.height < contentSize.height else { return false }

            contentOffset.line = contentSize.height - frame.size.height

        default: return false
        }

        invalidate()
        return true
    }
}
