import Foundation

public struct Size: Sendable, Equatable, CustomStringConvertible {
    public var width: Extended
    public var height: Extended

    public static var zero: Size { Size(width: 0, height: 0) }

    public var description: String { "\(width)x\(height)" }

    var isZero: Bool { width.intValue == 0 && height.intValue == 0 }
}

extension Size {
    func intersection(_ rhs: Size) -> Size {
        .init(width: min(width, rhs.width), height: min(height, rhs.height))
    }

    func union(_ rhs: Size) -> Size {
        .init(width: max(width, rhs.width), height: max(height, rhs.height))
    }

    static func + (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: Size, rhs: Size) -> Size {
        .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}
