
/// A `Control` represents something on the screen that has a frame. It can be a Layout like `HStack` or `VStack`, or a concrete view like `Text`.
///
/// Modifier views like `Border` or `Background` are not controls, but instead they _modify_ the controls in their hierarchy. This is especially true if they contain aggregations like `Group` or `ForEach`.
@MainActor internal protocol Control: AnyObject {
    var frame: Rect { get set }
    var global: Rect { get }
    func size(proposedSize: Size) -> Size

    /// Perform layout for this Control inside the specified Rect.
    ///
    /// Nodes must set their `frame` to be the entire Rect, but could layout in a smaller rect, which they can set as `bounds`.
    ///
    /// These two values are often the same thing, especially for simple controls, but may be adjusted by modifiiers like ``View/padding(_:_:)`` and ``View/frame(width:height:alignment:)``.
    ///
    /// - Parameter rect: The rect that this node must layout in.
    /// - Returns: The bounds of the node.
    func layout(rect: Rect) -> Rect
    func verticalFlexibility(width: Extended) -> Extended
    func horizontalFlexibility(height: Extended) -> Extended

    var sizeElement: Visitor.SizeElement { get }
    var layoutElement: Visitor.LayoutElement { get }
    var parent: Node? { get }
    func relative(to: Node?) -> Rect
}

extension Control {
    func verticalFlexibility(width: Extended) -> Extended {
        let minSize = size(
            proposedSize: Size(width: width, height: 0)
        )

        let maxSize = size(
            proposedSize: Size(width: width, height: .infinity)
        )

        return maxSize.height - minSize.height
    }

    func horizontalFlexibility(height: Extended) -> Extended {
        let minSize = size(
            proposedSize: Size(width: 0, height: height)
        )

        let maxSize = size(
            proposedSize: Size(width: .infinity, height: height)
        )

        return maxSize.width - minSize.width
    }

    @inline(__always)
    var sizeElement: Visitor.SizeElement {
        .init(node: self) { [weak self] proposedSize in
            self?.size(proposedSize: proposedSize) ?? .zero
        }
    }

    @inline(__always)
    var layoutElement: Visitor.LayoutElement {
        .init(
            node: self
        ) { [weak self] rect in
            self?.layout(rect: rect) ?? .zero
        } adjust: { [weak self] position in
            self?.frame.position += position
        } global: { [weak self] in
            self?.global ?? .zero
        }
    }
}
