import Foundation

nonisolated public struct Position: Hashable, Sendable {
    public var column: Extended
    public var line: Extended

    public init(column: Extended, line: Extended) {
        self.column = column
        self.line = line
    }

    public static var zero: Position { Position(column: 0, line: 0) }

    public func clamped(to bounds: Position) -> Self {
        return .init(
            column: column.clamped(to: bounds.column),
            line: line.clamped(to: bounds.line)
        )
    }
}

nonisolated extension Position: nonisolated CustomStringConvertible {
    public var description: String { "(\(column), \(line))" }
}

nonisolated extension Position: nonisolated CustomDebugStringConvertible {
    public var debugDescription: String { description }
}

nonisolated extension Position: nonisolated AdditiveArithmetic {
    public static func +(lhs: Self, rhs: Self) -> Self {
        Position(column: lhs.column + rhs.column, line: lhs.line + rhs.line)
    }

    public static func - (lhs: Position, rhs: Position) -> Position {
        Position(column: lhs.column - rhs.column, line: lhs.line - rhs.line)
    }

    public static prefix func - (p: Position) -> Position {
        return .init(column: -p.column, line: -p.line)
    }
}
