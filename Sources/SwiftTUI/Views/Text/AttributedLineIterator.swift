import Foundation

struct AttributedLineIterator: IteratorProtocol, Sequence {
    let rect: Rect
    let string: AttributedString
    var currentIndex: AttributedString.Index
    var endOfWord: AttributedString.Index
    var startOfNextWord: AttributedString.Index
    var endOfLine: AttributedString.Index
    var currentRun: AttributedString.Runs.Index
    var position: Position
    var currentWordFits = true

    init(rect: Rect, string: AttributedString) {
        self.rect = rect
        self.string = string
        self.currentIndex = string.startIndex
        self.startOfNextWord = string.endIndex
        self.endOfWord = string.endIndex
        self.endOfLine = string.endIndex
        self.position = rect.topLeft
        self.currentRun = string.runs.startIndex
        (endOfWord, startOfNextWord, endOfLine) = nextWord()
    }

    func nextWord() -> (endOfWord: AttributedString.Index, startOfNextWord: AttributedString.Index, endOfLine: AttributedString.Index) {
        guard currentIndex != string.endIndex else { return (string.endIndex, string.endIndex, string.endIndex) }

        let endOfLine = string[currentIndex...].characters.firstIndex(where: \.isNewline) ?? string.endIndex
        let endOfCurrentWord = string[currentIndex...].characters.dropFirst().firstIndex { $0.isWhitespace } ?? string.endIndex
        let startOfNextWord = string[endOfCurrentWord...].characters.firstIndex { !$0.isWhitespace } ?? string.endIndex

        return (endOfCurrentWord, startOfNextWord, endOfLine)
    }

    func skipWhitespace() -> AttributedString.Index {
        string[currentIndex...].characters.dropFirst().firstIndex { !$0.isWhitespace } ?? string.endIndex
    }

    mutating func run() -> AttributeContainer {
        guard currentRun < string.runs.endIndex else { return .init() }

        while !string.runs[currentRun].range.contains(currentIndex) {
            currentRun = string.runs.index(after: currentRun)
        }

        return string.runs[currentRun].attributes
    }

    mutating func next() -> (Position, Cell, AttributeContainer)? {
        if !rect.contains(position) {
            position.column = rect.minColumn
            position.line += 1

            // The line break will eat any & all whitespace between words.
            if currentIndex == endOfLine, endOfLine != string.endIndex {
                currentIndex = string.characters.index(after: currentIndex)
                (endOfWord, startOfNextWord, endOfLine) = nextWord()
            } else if currentWordFits {
                currentIndex = startOfNextWord
                (endOfWord, startOfNextWord, endOfLine) = nextWord()
            }

            currentWordFits = true
        }

        guard rect.contains(position) else { return nil }
        defer { position.column += 1 }

        guard currentIndex != string.endIndex else {
            return (position, .init(char: " "), .init())
        }

        if currentIndex == endOfLine || !currentWordFits {
            return (position, .init(char: " "), run())
        }

        if currentIndex == endOfWord {
            (endOfWord, startOfNextWord, endOfLine) = nextWord()

            if string.characters.distance(from: currentIndex, to: endOfWord) > (rect.maxColumn - position.column + 1).intValue {
                // If the current word doesn't fit, we can skip any whitespace between currentIndex and the next word.
                // We've already handled the case where currentIndex is a newline.
                currentIndex = skipWhitespace()
                currentWordFits = false
                return (position, .init(char: " "), run())
            }
        }

        defer { currentIndex = string.characters.index(after: currentIndex) }
        return (position, .init(char: string.characters[currentIndex]), run())
    }

}

