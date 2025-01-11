
/// A `Control` represents something on the screen that has a frame. It can be a Layout like `HStack` or `VStack`, or a concrete view like `Text`.
///
/// Modifier views like `Border` or `Background` are not controls, but instead they _modify_ the controls in their hierarchy. This is especially true if they contain aggregations like `Group` or `ForEach`.
@MainActor internal protocol Control: AnyObject {
    var frame: Rect { get }
    var global: Rect { get }
    // func move(by: Position)
    func size(proposedSize: Size) -> Size
    func layout(rect: Rect) -> Rect
    func verticalFlexibility(width: Extended) -> Extended
    func horizontalFlexibility(height: Extended) -> Extended
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
}
