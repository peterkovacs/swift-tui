struct Window<Element> {
    var elements: [Element]
    var size: Size
    var offset: Position

    init(
        repeating element: Element,
        size: Size
    ) {
        self.elements = .init(repeating: element, count: size.width.intValue * size.height.intValue)
        self.size = size
        self.offset = .zero
    }

    init<Seq: Sequence>(
        _ input: Seq,
        size: Size
    ) where Seq.Element == Element {
        self.elements = Array(input)
        self.size = size
        self.offset = .zero

        assert(size.width.intValue * size.height.intValue == elements.count)
    }

    func isValid(_ coord: Position) -> Bool {
        let coord = coord + offset
        return (
            coord.column < size.width &&
            coord.column >= 0 &&

            coord.line < size.height &&
            coord.line >= 0
        )
    }

    mutating func with(offset: Position, _ action: (inout Self) -> Void) {
        self.offset += offset
        action(&self)
        self.offset -= offset
    }

    subscript(_ coord: Position) -> Element {
        _read {
            let p = coord + offset
            assert(isValid(coord), "coordinate out of bounds")
            let i = (p.line * size.width + p.column).intValue
            yield elements[i]
        }

        _modify {
            let p = coord + offset
            let i = (p.line * size.width + p.column).intValue
            yield &elements[i]
        }
    }

    subscript<T>(_ coord: Position, default default: T) -> T where Optional<T> == Element {
        _read {
            let p = coord + offset
            let i = (p.line * size.width + p.column).intValue
            yield elements[i] ?? `default`
        }

        _modify {
            let p = coord + offset
            let i = (p.line * size.width + p.column).intValue
            if elements[i] == nil { elements[i] = `default` }
            yield &elements[i]!
        }
    }

    mutating func write<T>(at coord: Position, default: T,  _ action: (inout T) -> Void) where Optional<T> == Element {
        let p = coord + offset
        var cell = elements[(p.line * size.width + p.column).intValue] ?? `default`
        action(&cell)
        elements[(p.line * size.width + p.column).intValue] = cell
    }

}

extension Window: Sequence {
    struct CoordinateIterator: Sequence, IteratorProtocol {
        let size: Size
        var coordinate: Position

        mutating func next() -> Position? {
            if coordinate.column >= size.width {
                coordinate = .init(column: 0, line: coordinate.line + 1) }
            if coordinate.line >= size.height { return nil }
            defer { coordinate.column += 1 }

            return coordinate
        }
    }

    struct RowIterator: Sequence, IteratorProtocol {
        let size: Size
        var coordinate: Position

        mutating func next() -> Position? {
            if coordinate.column >= size.width { return nil }
            defer { coordinate.column += 1 }

            return coordinate
        }
    }

    struct ColumnIterator: Sequence, IteratorProtocol {
        let size: Size
        var coordinate: Position

        mutating func next() -> Position? {
            if coordinate.line >= size.height { return nil }
            defer { coordinate.line += 1 }

            return coordinate
        }
    }

    struct Iterator: IteratorProtocol {
        let grid: Window
        var iterator: CoordinateIterator

        mutating func next() -> Element? {
            guard let coordinate = iterator.next() else { return nil }
            return grid[ coordinate ]
        }
    }

    func makeIterator() -> Iterator {
        .init(grid: self, iterator: indices)
    }

    var indices: CoordinateIterator {
        return CoordinateIterator(size: size, coordinate: .zero)
    }

    func map<U>(_ f: (Element) throws -> U) rethrows -> Window<U> {
        return try Window<U>(elements.map(f), size: size)
    }

    func flatMap<U>(_ f: (Element) throws -> U?) rethrows -> Window<U>? {
        let elements = try self.elements.compactMap(f)
        guard elements.count == self.elements.count else { return nil }
        return Window<U>(elements, size: size)
    }
}


extension Window: Equatable where Element: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        guard lhs.size == rhs.size else { return false }
        return lhs.elementsEqual(rhs)
    }
}

extension Window: CustomStringConvertible where Element: CustomStringConvertible {
    var description: String {
        var result = ""

        for y in 0..<size.height.intValue {
            for x in 0..<size.width.intValue {
                result.append(self[.init(column: Extended(x), line: Extended(y))].description)
            }

            result.append("\n")
        }

        return result
    }
}

extension Window: Hashable where Element: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(
            indices.map { self[$0] }
        )
    }
}

extension Window: Sendable where Element: Sendable {}
