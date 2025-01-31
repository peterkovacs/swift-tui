import Foundation

public struct Size: Sendable, Equatable, CustomStringConvertible {
    public var width: Extended
    public var height: Extended

    public static var zero: Size { Size(width: 0, height: 0) }

    public var description: String { "\(width)x\(height)" }

    public var isZero: Bool { width.intValue == 0 && height.intValue == 0 }

    public func clamped(to bounds: Size) -> Self {
        return .init(
            width: width.clamped(to: bounds.width),
            height: height.clamped(to: bounds.height)
        )
    }

}

extension Size {
    public static func + (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    public static func - (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    public mutating func expand(to rhs: Size) {
        width = max(width, rhs.width)
        height = max(height, rhs.height)
    }

    public func expanding(to rhs: Size) -> Size {
        var copy = self
        copy.expand(to: rhs)
        return copy
    }
}
