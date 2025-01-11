@MainActor protocol LayoutVisitor {
    mutating func visit(node: Control, size: @escaping (Size) -> Size)
}

enum Visitor {
    struct LayoutElement {
        /// The node that is participating in Layout
        let node: any Control

        /// A method that will layout the control within the given Rect
        let layout: (SwiftTUI.Rect) -> SwiftTUI.Rect

        /// A method that will set the controls frame, specified in parent-relative coordinates.
        let frame: (SwiftTUI.Rect) -> Void

        /// A method that will return the global coordinates of the control.
        let global: () -> SwiftTUI.Rect
    }

    /// A Visitor.Layout recursively visits each `Control` in a `Node` hierarchy and is called with the `layout` method of the control.
    @MainActor protocol Layout {
        mutating func visit(layout: LayoutElement)
    }

    struct SizeElement {
        let node: any Control
        let size: (SwiftTUI.Size) -> SwiftTUI.Size
    }

    @MainActor protocol Size {
        mutating func visit(size: SizeElement)
    }
}
