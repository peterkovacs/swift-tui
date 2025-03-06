public enum ScrollIndicatorVisibility: Sendable, Hashable {
    case automatic
    case hidden
    case visible

    func size(if notHidden: Bool) -> Extended {
        switch self {
        case .automatic: notHidden ? 1 : 0
        case .hidden: 0
        case .visible: 1
        }
    }
}

public struct ScrollView<Content: View>: View, PrimitiveView {
    let axes: LayoutAxis.Set
    let indiciatorVisibility: ScrollIndicatorVisibility
    let content: Content

    public init(_ axes: LayoutAxis.Set = [.vertical], indiciatorVisibility: ScrollIndicatorVisibility = .automatic, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.indiciatorVisibility = indiciatorVisibility
        self.content = content()
    }

    func build(parent: Node?) -> Node {
        let node = ScrollViewNode(
            view: content,
            parent: parent,
            axes: axes,
            indicatorVisiblity: indiciatorVisibility
        )

        return node
    }

    func update(node: Node) {
        guard let node = node as? ScrollViewNode else { fatalError() }

        node.axes = axes
        node.indicatorVisiblity = indiciatorVisibility
        node.children[0].update(view: content.view)

        // TODO: Might need to do something to handle contentOffset changes.
    }
}

class ScrollViewNode: RootNode {
    var axes: LayoutAxis.Set
    var indicatorVisiblity: ScrollIndicatorVisibility { didSet { if indicatorVisiblity != oldValue { invalidateLayout() } } }
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

    init<T: View>(view: T, parent: Node?, axes: LayoutAxis.Set, indicatorVisiblity: ScrollIndicatorVisibility) {
        self.axes = axes
        self.indicatorVisiblity = indicatorVisiblity
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
        contentSize = layoutVisitor.layout(
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

        let indicatorSize = Size(
            width:  axes.contains(.horizontal) ? indicatorVisiblity.size(if: contentSize.width  > rect.size.width)  : 0,
            height: axes.contains(.vertical)   ? indicatorVisiblity.size(if: contentSize.height > rect.size.height) : 0
        )

        contentSize = contentSize + indicatorSize

        frame = .init(
            position: rect.position,
            size:  (contentSize + indicatorSize).constraining(to: rect.size)
        )

        // Reset the contentOffset if we would have been scrolled past the end given the current layout.
        if axes.contains(.vertical) && rect.size.height + contentOffset.line > contentSize.height {
            contentOffset.line = max(contentSize.height - rect.size.height, 0)
        }

        if axes.contains(.horizontal) && rect.size.width + contentOffset.column > contentSize.width {
            contentOffset.column = max(contentSize.width - rect.size.width, 0)
        }

        return frame
    }

    override func size(proposedSize: Size) -> Size {
        let contentSize = super.size(
            proposedSize:  .init(
                width: axes.contains(.horizontal) ? .infinity : proposedSize.width,
                height: axes.contains(.vertical) ? .infinity : proposedSize.height
            )
        )

        let indicatorSize: Size = .init(
            width:  axes.contains(.horizontal) ? indicatorVisiblity.size(if: contentSize.width  > proposedSize.width)  : 0,
            height: axes.contains(.vertical)   ? indicatorVisiblity.size(if: contentSize.height > proposedSize.height) : 0
        )

        let combinedSize = (contentSize + indicatorSize).constraining(to: proposedSize).expanding(to: indicatorSize)

        return .init(
            width: axes.contains(.horizontal) ? proposedSize.width : combinedSize.width,
            height: axes.contains(.vertical) ? proposedSize.height : combinedSize.height
        )
    }

    var hasFocusableElements: Bool {
        focusVisitor.visited.contains { $0.isFocusable() }
    }

    override func focus<T>(visitor: inout T) where T : Visitor.Focus {
        visitor.visit(focus: focusableElement)
    }

    func horizontalScrollBar() -> Rect? {
        guard axes.contains(.horizontal) else { return nil }

        let size = indicatorVisiblity.size(if: contentSize.width  > global.size.width)
        guard size > 0 else { return nil }

        let frame = global.size.width.intValue
        let width = contentSize.width.intValue
        let offset = contentOffset.column.intValue
        let length = ((global.size.width) * (global.size.width)) / contentSize.width

        let startPosition = Extended(
            Int(
                (Double(frame) * (Double(offset) / Double(width)))
            )
        )

        return .init(
            column: global.minColumn + startPosition,
            line: global.maxLine,
            width: length,
            height: size
        )
    }

    func verticalScrollBar() -> Rect? {
        guard axes.contains(.vertical) else { return nil }

        let size = indicatorVisiblity.size(if: contentSize.width  > global.size.width)
        guard size > 0 else { return nil }

        let frame = global.size.height.intValue
        let height = contentSize.height.intValue
        let offset = contentOffset.line.intValue
        let length = ((global.size.height) * (global.size.height)) / contentSize.height

        let startPosition = Extended(
            Int(
                (Double(frame) * (Double(offset) / Double(height)))
            )
        )


        return .init(
            column: global.maxColumn,
            line: global.minLine + startPosition,
            width: size,
            height: length
        )
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        let global = global
        guard let rect = global.intersection(rect) else { return }

        let indicatorSize: Size = .init(
            width:  axes.contains(.horizontal) ? indicatorVisiblity.size(if: contentSize.width  > global.size.width)  : 0,
            height: axes.contains(.vertical)   ? indicatorVisiblity.size(if: contentSize.height > global.size.height) : 0
        )

        window.with(offset: -contentOffset + global.position) { window in
            children[0].draw(rect: rect + contentOffset - global.position, into: &window)
        }

        if let scrollBar = horizontalScrollBar() {
            for i in global.bottom where rect.contains(i) && global.bottomRight != i {
                window[i] = .init(char: scrollBar.contains(i) ? "█" : "░")
            }

            window[global.bottomRight] = .init(char: "░")
        }

        if let scrollBar = verticalScrollBar() {
            for i in global.right where rect.contains(i) && global.bottomRight != i {
                window[i] = .init(char: scrollBar.contains(i) ? "█" : "░")
            }

            window[global.bottomRight] = .init(char: "░")
        }
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

        if focusManager.handle(key: key), let focusedElement = focusManager.focusedElement {
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

            contentOffset.column += 1

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
