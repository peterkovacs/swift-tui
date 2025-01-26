import CoreFoundation
import Foundation

@usableFromInline
struct LineItemInput {
    @usableFromInline
    var size: Extended
    @usableFromInline
    var spacing: Extended
    @usableFromInline
    var isLineBreakView: Bool = false
    @usableFromInline
    var shouldStartInNewLine: Bool = false
}

@usableFromInline
protocol LineBreaking {
    @inlinable
    func wrapItemsToLines(items: LineBreakingInput, in availableSpace: Extended) -> LineBreakingOutput
}

@usableFromInline
typealias LineBreakingInput = [LineItemInput]

@usableFromInline
typealias IndexedLineBreakingInput = [(offset: Int, element: LineItemInput)]

@usableFromInline
typealias LineBreakingOutput = [LineOutput]

@usableFromInline
typealias LineOutput = [LineItemOutput]

@usableFromInline
struct LineItemOutput: Equatable {
    @usableFromInline
    let index: Int
    @usableFromInline
    var size: Extended
    @usableFromInline
    var leadingSpace: Extended

    @inlinable
    init(index: Int, size: Extended, leadingSpace: Extended) {
        self.index = index
        self.size = size
        self.leadingSpace = leadingSpace
    }
}

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: LineBreakingInput, in availableSpace: Extended) -> LineBreakingOutput {
        if items.isEmpty {
            return []
        }
        let count = items.count
        var costs: [Extended] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        if availableSpace == .infinity {
            breaks[count] = 0
        } else {
            for end in 1 ... count {
                for start in (0 ..< end).reversed() {
                    let itemsToEvaluate: IndexedLineBreakingInput = (start ..< end).map { ($0, items[$0]) }
                    guard let calculation = sizes(of: itemsToEvaluate, availableSpace: availableSpace) else { continue }
                    let remainingSpace = calculation.remainingSpace
                    let spacePenalty = remainingSpace * remainingSpace

                    let stretchPenalty = zip(itemsToEvaluate, calculation.items)
                        .lazy
                        .map { (item, calculation) in
                            let deviation = calculation.size - item.element.size
                            return deviation * deviation
                        }
                        .reduce(0, +)

                    let bias = Extended(count - start) * 5 // Introduce a small bias to prefer breaks that fill earlier lines more
                    let cost = costs[start] + spacePenalty + stretchPenalty + bias
                    if cost < costs[end] {
                        costs[end] = cost
                        breaks[end] = start
                    }
                }
            }
        }

        var result: LineBreakingOutput = []
        var end = items.count
        while let start = breaks[end] {
            let line = sizes(of: (start..<end).map { ($0, items[$0]) }, availableSpace: availableSpace)?.items ?? (start..<end).map { index in
                LineItemOutput(
                    index: index,
                    size: items[index].size,
                    leadingSpace: index == start ? 0 : items[index].spacing
                )
            }
            result.insert(line, at: 0)
            end = start
        }
        return result
    }
}

@usableFromInline
typealias SizeCalculation = (items: LineOutput, remainingSpace: Extended)

@inlinable
func sizes(of items: IndexedLineBreakingInput, availableSpace: Extended) -> SizeCalculation? {
    if items.isEmpty {
        return nil
    }
    // Handle line break view
    let positionOfLineBreak = items.lastIndex(where: \.element.isLineBreakView)
    if let positionOfLineBreak, positionOfLineBreak > 0 {
        return nil
    }
    var items = items
    if let positionOfLineBreak, case let afterLineBreak = items.index(after: positionOfLineBreak), afterLineBreak < items.endIndex {
        items[afterLineBreak].element.spacing = 0
    }
    // Handle manual new line modifier
    let numberOfNewLines = items.count(where: \.element.shouldStartInNewLine)
    if numberOfNewLines > 1 {
        return nil
    } else if numberOfNewLines == 1, !items[0].element.shouldStartInNewLine {
        return nil
    }
    // Calculate total size
    let totalSizeOfItems = items.reduce(0) { $0 + $1.element.size } + items.dropFirst().reduce(0) { $0 + $1.element.spacing }
    if totalSizeOfItems > availableSpace {
        return nil
    }

    var result: LineOutput = items.map { LineItemOutput(index: $0.offset, size: $0.element.size, leadingSpace: $0.element.spacing) }
    result[0].leadingSpace = 0

    return SizeCalculation(items: result, remainingSpace: availableSpace - totalSizeOfItems)
}
