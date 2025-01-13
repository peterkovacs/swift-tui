enum Visitor {
    struct LayoutElement {
        /// The node that is participating in Layout
        let node: any Control

        /// A method that will layout the control within the given Rect.
        /// - Parameter rect: A rect which has been calculated by a corresponding SizeElement that is guaranteed to fit the element.
        /// - Returns: The actual size of the calculated frame which must be less than or equal to `rect`.
        let layout: (_ rect: Rect) -> Rect

        /// A method that will set the controls frame, specified in parent-relative coordinates.
        let frame: (Rect) -> Rect

        /// A method that will return the global coordinates of the control.
        let global: () -> Rect
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
