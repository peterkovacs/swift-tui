import Foundation

public struct Size: Sendable, Equatable, CustomStringConvertible {
    public var width: Extended
    public var height: Extended

    public static var zero: Size { Size(width: 0, height: 0) }

    public var description: String { "\(width)x\(height)" }

    var isZero: Bool { width.intValue == 0 && height.intValue == 0 }

    public func clamped(to bounds: Size) -> Self {
        return .init(
            width: width.clamped(to: bounds.width),
            height: height.clamped(to: bounds.height)
        )
    }

}

extension Size {
    static func + (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    mutating func expand(to rhs: Size) {
        width = max(width, rhs.width)
        height = max(height, rhs.height)
    }
}
