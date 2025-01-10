import Foundation

struct Rect: Equatable {
    var position: Position
    var size: Size

    init(position: Position, size: Size) {
        self.position = position
        self.size = size
    }

    init(minColumn: Extended, minLine: Extended, maxColumn: Extended, maxLine: Extended) {
        self.position = Position(column: minColumn, line: minLine)
        self.size = Size(width: maxColumn - minColumn + 1, height: maxLine - minLine + 1)
    }

    init(column: Extended, line: Extended, width: Extended, height: Extended) {
        self.position = Position(column: column, line: line)
        self.size = Size(width: width, height: height)
    }

    static var zero: Rect { Rect(position: .zero, size: .zero) }

    var minLine: Extended { position.line }
    var minColumn: Extended { position.column }
    var maxLine: Extended { position.line + size.height - 1 }
    var maxColumn: Extended { position.column + size.width - 1 }

    /// The smallest rectangle that contains the two source rectangles.
    func union(_ r2: Rect) -> Rect {
        if r2.size.isZero { return self }

        return Rect(
            minColumn: min(minColumn, r2.minColumn),
            minLine: min(minLine, r2.minLine),
            maxColumn: max(maxColumn, r2.maxColumn),
            maxLine: max(maxLine, r2.maxLine)
        )
    }

    // The overlapping portions
    func intersection(_ rhs: Rect) -> Rect? {
        if rhs.size.isZero { return self }
        if size.isZero { return rhs }

        let result = Rect(
            minColumn: max(minColumn, rhs.minColumn),
            minLine: max(minLine, rhs.minLine),
            maxColumn: min(maxColumn, rhs.maxColumn),
            maxLine: min(maxLine, rhs.maxLine)
        )

        if result.size.width > 0 && result.size.height > 0 {
            return result
        }
        return nil
    }

    func contains(_ position: Position) -> Bool {
        position.column >= minColumn &&
        position.line >= minLine &&
        position.column <= maxColumn &&
        position.line <= maxLine
    }
}

extension Rect: CustomStringConvertible {
    var description: String { "\(position) \(size)" }
}

extension Rect {
    var indices: some Collection<Position> {
        CellGrid<Cell>.CoordinateIterator(size: size, coordinate: .zero).lazy.map { $0 + position }
    }

    var top: some Collection<Position> {
        (minColumn.intValue...maxColumn.intValue).lazy.map {
            Position(column: Extended($0), line: minLine)
        }
    }

    var right: some Collection<Position> {
        (minLine.intValue...maxLine.intValue).lazy.map {
            Position(column: maxColumn, line: Extended($0))
        }
    }

    var bottom: some Collection<Position> {
        (minColumn.intValue...maxColumn.intValue).lazy.map {
            Position(column: Extended($0), line: maxLine)
        }
    }

    var left: some Collection<Position> {
        (minLine.intValue...maxLine.intValue).lazy.map {
            Position(column: minColumn, line: Extended($0))
        }
    }
}
