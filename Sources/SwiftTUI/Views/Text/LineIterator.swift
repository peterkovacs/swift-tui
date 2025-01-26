struct LineIterator: IteratorProtocol, Sequence {
    let rect: Rect
    let string: String
    var currentIndex: String.Index
    var endOfWord: String.Index
    var startOfNextWord: String.Index
    var endOfLine: String.Index
    var position: Position
    var currentWordFits = true

    init(rect: Rect, string: String) {
        self.rect = rect
        self.string = string
        self.currentIndex = string.startIndex
        self.startOfNextWord = string.endIndex
        self.endOfWord = string.endIndex
        self.endOfLine = string.endIndex
        self.position = rect.topLeft
        (endOfWord, startOfNextWord, endOfLine) = nextWord()
    }

    func nextWord() -> (endOfWord: String.Index, startOfNextWord: String.Index, endOfLine: String.Index) {
        guard currentIndex != string.endIndex else { return (string.endIndex, string.endIndex, string.endIndex) }

        let endOfLine = string[currentIndex...].firstIndex(where: \.isNewline) ?? string.endIndex
        let endOfCurrentWord = string[currentIndex...].dropFirst().firstIndex { $0.isWhitespace } ?? string.endIndex
        let startOfNextWord = string[endOfCurrentWord...].firstIndex { !$0.isWhitespace } ?? string.endIndex

        return (endOfCurrentWord, startOfNextWord, endOfLine)
    }

    func skipWhitespace() -> String.Index {
        string[currentIndex...].dropFirst().firstIndex { !$0.isWhitespace } ?? string.endIndex
    }

    mutating func next() -> (Position, Cell)? {
        if !rect.contains(position) {
            position.column = rect.minColumn
            position.line += 1

            // The line break will eat any & all whitespace between words.
            if currentIndex == endOfLine, endOfLine != string.endIndex {
                currentIndex = string.index(after: currentIndex)
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
            return (position, .init(char: " "))
        }

        if currentIndex == endOfLine || !currentWordFits {
            return (position, .init(char: " "))
        }

        if currentIndex == endOfWord {
            (endOfWord, startOfNextWord, endOfLine) = nextWord()

            if string.distance(from: currentIndex, to: endOfWord) > (rect.maxColumn - position.column + 1).intValue {
                // If the current word doesn't fit, we can skip any whitespace between currentIndex and the next word.
                // We've already handled the case where currentIndex is a newline.
                currentIndex = skipWhitespace()
                currentWordFits = false
                return (position, .init(char: " "))
            }
        }

        defer { currentIndex = string.index(after: currentIndex) }
        return (position, .init(char: string[currentIndex]))
    }

}

