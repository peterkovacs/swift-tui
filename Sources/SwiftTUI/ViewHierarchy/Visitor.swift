enum Visitor {
    struct LayoutElement {
        /// The node that is participating in Layout
        let node: any Control

        /// A method that will layout the control within the given Rect.
        /// - Parameter rect: A rect which has been calculated by a corresponding SizeElement that is guaranteed to fit the element.
        /// - Returns: The actual size of the calculated frame which must be less than or equal to `rect`.
        let layout: (_ rect: Rect) -> Rect

        /// A method that will set the final position of the frame
        let adjust: (Position) -> ()

        /// A method that will return the global coordinates of the control.
        let global: () -> Rect
    }

    /// A Visitor.Layout recursively visits each `Control` in a `Node` hierarchy and is called with the `layout` method of the control.
    @MainActor protocol Layout {
        mutating func visit(layout: LayoutElement)
    }

    struct SizeElement {
        /// The node that is calculating Size
        let node: any Control

        /// A method that will return the actual Size of a control given a proposedSize.
        let size: (_ proposedSize: SwiftTUI.Size) -> SwiftTUI.Size
    }

    @MainActor protocol Size {
        mutating func visit(size: SizeElement)
    }

    struct FocusableElement {
        let node: any Focusable

        /// A method that calculates if an element is currently focusable.
        let isFocusable: () -> Bool

        /// A method that handles a Key event.
        let handle: (_ key: Key) -> Bool

        /// A method that resigns the firstResponder 
        let resignFirstResponder: () -> Void
        let becomeFirstResponder: () -> Void
    }

    @MainActor protocol Focus {
        mutating func visit(focus: FocusableElement)
    }
}

extension Visitor.FocusableElement: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(node))
    }
}

extension Visitor.FocusableElement: Equatable {
    static func == (lhs: Visitor.FocusableElement, rhs: Visitor.FocusableElement) -> Bool {
        lhs.node === rhs.node
    }
}
