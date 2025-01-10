
@MainActor internal protocol Control: AnyObject {
    var frame: Rect { get }
    var global: Rect { get }
    func move(by: Position)
    func size(proposedSize: Size) -> Size
    func layout(size: Size) -> Size
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
