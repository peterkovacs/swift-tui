import Foundation
import CUnicode

public struct Key: Sendable, Equatable {
    public let key: Value
    public let modifiers: Modifiers

    init(_ key: Value, modifiers: Modifiers = []) {
        self.key = key
        self.modifiers = modifiers
        self.normalize()
    }

    static func fromMouseEvent(
        mouse: Int,
        position: Position,
        suffix: Unicode.Scalar
    ) -> Key? {
        if suffix == "M" {
            if mouse & 32 == 32 {
                switch mouse & 0x3 {
                case 0, 1, 2:
                    return Key(
                        .mouseDrag(button: mouse & 0x3, at: position),
                        modifiers: .init(sgr: mouse)
                    )
                default:
                    return Key(
                        .mouseMove(position),
                        modifiers: .init(sgr: mouse)
                    )
                }
            }

            if mouse & 64 == 64 {
                switch mouse & 0x1 {
                case 1:
                    return Key(
                        .mouseScrollUp(position),
                        modifiers: .init(sgr: mouse)
                    )
                default:
                    return Key(
                        .mouseScrollDown(position),
                        modifiers: .init(sgr: mouse)
                    )
                }
            }

            switch mouse & 3 {
            case 0, 1, 2:
                return Key(
                    .mouseDown(button: mouse & 0x3, at: position),
                    modifiers: .init(sgr: mouse)
                )
            default: return nil
            }
        } else if suffix == "m" {
            switch mouse & 3 {
            case 0, 1, 2:
                return Key(
                    .mouseUp(button: mouse & 0x3, at: position),
                    modifiers: .init(sgr: mouse)
                )
            default: return nil
            }
        }

        return nil
    }

    public enum Value: Sendable, Hashable, ExpressibleByUnicodeScalarLiteral {
        public init(unicodeScalarLiteral value: UnicodeScalar) {
            self = .char(value)
        }


        public typealias ExtendedGraphemeClusterLiteralType = Character

        public typealias UnicodeScalarLiteralType = UnicodeScalar

        case char(Unicode.Scalar)
        case up, down, left, right
        case home, end, pageUp, pageDown
        case insert, backspace
        case f1,  f2,  f3,  f4,  f5,  f6,  f7,  f8,  f9,  f10,
             f11, f12, f13, f14, f15, f16, f17, f18, f19, f20

        case mouseMove(Position)
        case mouseDown(button: Int, at: Position)
        case mouseUp(button: Int, at: Position)
        case mouseDrag(button: Int, at: Position)
        case mouseScrollUp(Position)
        case mouseScrollDown(Position)


        // MARK: Key Aliases
        static let nul: Self     = "\u{0}"
        static let soh: Self     = "\u{1}"
        static let stx: Self     = "\u{2}"
        static let etx: Self     = "\u{3}"
        static let eot: Self     = "\u{4}"
        static let enq: Self     = "\u{5}"
        static let ack: Self     = "\u{6}"
        static let bel: Self     = "\u{7}"
        static let bs: Self      = "\u{8}"
        static let tab: Self     = "\u{9}"
        static let newLine: Self = "\u{a}"
        static let vt: Self      = "\u{b}"
        static let np: Self      = "\u{c}"
        static let enter: Self   = "\u{d}"
        static let so: Self      = "\u{e}"
        static let si: Self      = "\u{f}"
        static let dle: Self     = "\u{10}"
        static let dc1: Self     = "\u{11}"
        static let dc2: Self     = "\u{12}"
        static let dc3: Self     = "\u{13}"
        static let dc4: Self     = "\u{14}"
        static let nak: Self     = "\u{15}"
        static let syn: Self     = "\u{16}"
        static let etb: Self     = "\u{17}"
        static let can: Self     = "\u{18}"
        static let em: Self      = "\u{19}"
        static let sub: Self     = "\u{1a}"
        static let escape: Self  = "\u{1b}"
        static let fs: Self      = "\u{1c}"
        static let gs: Self      = "\u{1d}"
        static let rs: Self      = "\u{1e}"
        static let us: Self      = "\u{1f}"
        static let space: Self   = " "
        static let delete: Self  = "\u{7f}"
    }

    public struct Modifiers: Sendable, OptionSet {
        public let rawValue: Int

        public static let shift = Self(rawValue: 1 << 0)
        public static let ctrl = Self(rawValue: 1 << 1)
        public static let alt = Self(rawValue: 1 << 2)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(sgr: Int) {
            var value = 0

            // 4, 8, or 16 are added to any event that has
            // shift, alt (meta), or control
            if sgr & 4 != 0 {
                value = 1 << 0
            }

            if sgr & 8 != 0 {
                value = 1 << 2 | value
            }

            if sgr & 16 != 0 {
                value = 1 << 1 | value
            }

            self.rawValue = value
        }
    }

    var isControl: Bool {
        switch key {
        case .nul, .soh, .stx, .etx, .eot, .enq, .ack, .bel, .bs, .tab, .newLine,
             .vt, .np, .enter, .so, .si, .dle, .dc1, .dc2, .dc3, .dc4, .nak,
             .syn, .etb, .can, .em, .sub, .fs, .gs, .rs, .us, .delete:
            return true
        default:
            return false
        }
    }

    private mutating func normalize() {
        switch (key, modifiers) {
        case ("@", .ctrl):     self = .init("\u{0}")
        case ("a", .ctrl):     self = .init("\u{1}")
        case ("b", .ctrl):     self = .init("\u{2}")
        case ("c", .ctrl):     self = .init("\u{3}")
        case ("d", .ctrl):     self = .init("\u{4}")
        case ("e", .ctrl):     self = .init("\u{5}")
        case ("f", .ctrl):     self = .init("\u{6}")
        case ("g", .ctrl):     self = .init("\u{7}")
        case ("h", .ctrl):     self = .init("\u{8}")
        case ("i", .ctrl):     self = .init("\u{9}")
        case ("j", .ctrl):     self = .init("\u{a}")
        case ("k", .ctrl):     self = .init("\u{b}")
        case ("l", .ctrl):     self = .init("\u{c}")
        case ("m", .ctrl):     self = .init("\u{d}")
        case ("n", .ctrl):     self = .init("\u{e}")
        case ("o", .ctrl):     self = .init("\u{f}")
        case ("p", .ctrl):     self = .init("\u{10}")
        case ("q", .ctrl):     self = .init("\u{11}")
        case ("r", .ctrl):     self = .init("\u{12}")
        case ("s", .ctrl):     self = .init("\u{13}")
        case ("t", .ctrl):     self = .init("\u{14}")
        case ("u", .ctrl):     self = .init("\u{15}")
        case ("v", .ctrl):     self = .init("\u{16}")
        case ("w", .ctrl):     self = .init("\u{17}")
        case ("x", .ctrl):     self = .init("\u{18}")
        case ("y", .ctrl):     self = .init("\u{19}")
        case ("z", .ctrl):     self = .init("\u{1a}")
        case ("[", .ctrl):     self = .init("\u{1b}")
        case ("\\", .ctrl):    self = .init("\u{1c}")
        case ("]", .ctrl):     self = .init("\u{1d}")
        case ("^", .ctrl):     self = .init("\u{1e}")
        case ("_", .ctrl):     self = .init("\u{1f}")
        case ("?", .ctrl):     self = .init("\u{7f}")
        default: break
        }
    }

    func bytes() -> [UInt8] {
        switch (key, modifiers) {
        case (.char(let s), []):
            return Array(s.utf8)
        default:
            guard let key = KeyParser.mapping.first(where: { $0.value == self })?.key
            else { return [] }

            return Array(key.utf8)
        }
    }
}

/// Parse bytes from the fileHandle into `Key`s.
actor KeyParser: AsyncSequence {
    typealias Timeout = Task<Void, Never>

    enum State: Equatable {
        case initial
        case escape
        case escapeO
        case escapeSquareBracket
        case escapeSquareBracketLessThan
        case escapeSquareBracketLessThanDigit(Int)
        case escapeSquareBracketLessThanDigitSemicolon(Int)
        case escapeSquareBracketLessThanDigitDigit(Int, Int)
        case escapeSquareBracketLessThanDigitDigitSemicolon(Int, Int)
        case escapeSquareBracketLessThanDigitDigitDigit(Int, Int, Int)
        case escapeSquareBracketDigit(Int)
        case escapeSquareBracketDigitSemicolon(Int)
        case escapeSquareBracketDigitDigit(Int, Int)
    }

    var state: (state: State, timeout: Timeout?) = (.initial, nil)
    var fileHandle: FileHandle

    public init(fileHandle: consuming FileHandle = .standardInput) {
        self.state = (.initial, nil)
        self.fileHandle = fileHandle
    }

    // MARK: AsyncSequence

    public typealias Element = Key
    public nonisolated func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(owner: self)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let owner: KeyParser
        var iter: AsyncThrowingStream<Key, Error>.AsyncIterator? = nil

        init(owner: KeyParser) {
            self.owner = owner
        }

        public mutating func next() async throws -> Key? {
            if iter == nil {
                iter = await owner.parse().makeAsyncIterator()
            }

            return try await iter?.next()
        }
    }

    // MARK: Parse Input
    private var bytes: AsyncThrowingStream<UInt8, Error> {
        AsyncThrowingStream<UInt8, Error> { [fileHandle] continuation in
            fileHandle.readabilityHandler = { (fileHandle) in
                for byte in fileHandle.availableData {
                    continuation.yield(byte)
                }
            }

            continuation.onTermination = { termination in
                fileHandle.readabilityHandler = nil
            }
        }
    }

    enum DecodingError: Error {
        case invalidUTF8Encoding
    }

    // Normally you could just do `bytes.asyncScalars`, but since
    // this is only available on macOS, implementing our own.
    private var unicodeScalars: AsyncThrowingStream<Unicode.Scalar, Error> {
        let stream = AsyncThrowingStream<Unicode.Scalar, Error>.makeStream()

        enum State {
            case initial
            case parsing(Int32, [UInt8])
        }

        let task = Task {
            var state = State.initial
            do {
                for try await byte in bytes {
                    switch state {
                    case .initial:
                        let len = utf8_len(byte)
                        guard len > 0 else {
                            stream.continuation.finish(
                                throwing: DecodingError.invalidUTF8Encoding
                            )
                            return
                        }
                        guard len > 1 else {
                            stream.continuation.yield(.init(byte))
                            continue
                        }

                        state = .parsing(len, [byte])
                    case .parsing(let len, var array):
                        array.append(byte)

                        if array.count == len {
                            let codePoint = to_codepoint(array)
                            guard codePoint >= 0, let scalar = UnicodeScalar(codePoint) else {
                                stream.continuation.finish(
                                    throwing: DecodingError.invalidUTF8Encoding
                                )
                                return
                            }

                            stream.continuation.yield(scalar)
                            state = .initial
                        } else {
                            state = .parsing(len, array)
                        }
                    }
                }
            } catch {
                stream.continuation.finish(throwing: error)
            }
        }

        stream.continuation.onTermination = { termination in
            if case .cancelled = termination {
                task.cancel()
            }
        }

        return stream.stream
    }

    private func parse() -> AsyncThrowingStream<Key, Error> {
        let stream = AsyncThrowingStream<Key, Error>.makeStream()
        let task = Task {
            do {
                try await parse(continuation: stream.continuation)
            } catch {
                stream.continuation.finish(throwing: error)
            }
        }

        stream.continuation.onTermination = { _ in
            task.cancel()
        }

        return stream.stream
    }

    nonisolated static let mapping: [String: Key] = [
        // //    Arrow keys
        "\u{1b}[A":    Key(.up),
        "\u{1b}[B":    Key(.down),
        "\u{1b}[C":    Key(.right),
        "\u{1b}[D":    Key(.left),

        "\u{1b}[1;2A": Key(.up,    modifiers: .shift),
        "\u{1b}[1;2B": Key(.down,  modifiers: .shift),
        "\u{1b}[1;2C": Key(.right, modifiers: .shift),
        "\u{1b}[1;2D": Key(.left,  modifiers: .shift),

        "\u{1b}[OA":   Key(.up,    modifiers: .shift), // DECCKM
        "\u{1b}[OB":   Key(.down,  modifiers: .shift), // DECCKM
        "\u{1b}[OC":   Key(.right, modifiers: .shift), // DECCKM
        "\u{1b}[OD":   Key(.left,  modifiers: .shift), // DECCKM

        "\u{1b}[a":    Key(.up,    modifiers: .shift), // urxvt
        "\u{1b}[b":    Key(.down,  modifiers: .shift), // urxvt
        "\u{1b}[c":    Key(.right, modifiers: .shift), // urxvt
        "\u{1b}[d":    Key(.left,  modifiers: .shift), // urxvt

        "\u{1b}[1;3A": Key(.up,    modifiers: .alt),
        "\u{1b}[1;3B": Key(.down,  modifiers: .alt),
        "\u{1b}[1;3C": Key(.right, modifiers: .alt),
        "\u{1b}[1;3D": Key(.left,  modifiers: .alt),

        "\u{1b}[1;4A": Key(.up,    modifiers: [.shift, .alt]),
        "\u{1b}[1;4B": Key(.down,  modifiers: [.shift, .alt]),
        "\u{1b}[1;4C": Key(.right, modifiers: [.shift, .alt]),
        "\u{1b}[1;4D": Key(.left,  modifiers: [.shift, .alt]),

        "\u{1b}[1;5A": Key(.up,    modifiers: .ctrl),
        "\u{1b}[1;5B": Key(.down,  modifiers: .ctrl),
        "\u{1b}[1;5C": Key(.right, modifiers: .ctrl),
        "\u{1b}[1;5D": Key(.left,  modifiers: .ctrl),

        "\u{1b}[Oa":   Key(.up,    modifiers: [.ctrl, .alt]),    // urxvt
        "\u{1b}[Ob":   Key(.down,  modifiers: [.ctrl, .alt]),  // urxvt
        "\u{1b}[Oc":   Key(.right, modifiers: [.ctrl, .alt]), // urxvt
        "\u{1b}[Od":   Key(.left,  modifiers: [.ctrl, .alt]),  // urxvt

        "\u{1b}[1;6A": Key(.up,    modifiers: [.ctrl, .shift]),
        "\u{1b}[1;6B": Key(.down,  modifiers: [.ctrl, .shift]),
        "\u{1b}[1;6C": Key(.right, modifiers: [.ctrl, .shift]),
        "\u{1b}[1;6D": Key(.left,  modifiers: [.ctrl, .shift]),

        "\u{1b}[1;7A": Key(.up,    modifiers: [.ctrl, .alt]),
        "\u{1b}[1;7B": Key(.down,  modifiers: [.ctrl, .alt]),
        "\u{1b}[1;7C": Key(.right, modifiers: [.ctrl, .alt]),
        "\u{1b}[1;7D": Key(.left,  modifiers: [.ctrl, .alt]),

        "\u{1b}[1;8A": Key(.up,    modifiers: [.ctrl, .shift, .alt]),
        "\u{1b}[1;8B": Key(.down,  modifiers: [.ctrl, .shift, .alt]),
        "\u{1b}[1;8C": Key(.right, modifiers: [.ctrl, .shift, .alt]),
        "\u{1b}[1;8D": Key(.left,  modifiers: [.ctrl, .shift, .alt]),

        // Miscellaneous keys
        "\u{1b}[Z":    Key(.tab, modifiers: .shift),

        "\u{1b}[2~":   Key(.insert),
        "\u{1b}[3;2~": Key(.insert),                   // differ

        "\u{1b}[3~":   Key(.delete),
        "\u{1b}[3;3~": Key(.delete),                   // differ
        "\u{1b}[3;5~": Key(.delete, modifiers: .ctrl), // differ

        "\u{1b}[5~":   Key(.pageUp),
        "\u{1b}[5;3~": Key(.pageUp, modifiers: .alt),
        "\u{1b}[5;5~": Key(.pageUp, modifiers: .ctrl),
        "\u{1b}[5^":   Key(.pageUp, modifiers: .ctrl), // urxvt
        "\u{1b}[5;7~": Key(.pageUp, modifiers: [.ctrl, .alt]),

        "\u{1b}[6~":   Key(.pageDown),
        "\u{1b}[6;3~": Key(.pageDown, modifiers: .alt),
        "\u{1b}[6;5~": Key(.pageDown, modifiers: .ctrl),
        "\u{1b}[6^":   Key(.pageDown, modifiers: .ctrl), // urxvt
        "\u{1b}[6;7~": Key(.pageDown, modifiers: [.ctrl, .alt]),

        "\u{1b}[1~":   Key(.home),
        "\u{1b}[H":    Key(.home),                     // xterm, lxterm
        "\u{1b}[1;3H": Key(.home, modifiers: .alt),          // xterm, lxterm
        "\u{1b}[1;5H": Key(.home, modifiers: .ctrl),                 // xterm, lxterm
        "\u{1b}[1;7H": Key(.home, modifiers: [.ctrl, .alt]),      // xterm, lxterm
        "\u{1b}[1;2H": Key(.home, modifiers: .shift),                // xterm, lxterm
        "\u{1b}[1;4H": Key(.home, modifiers: [.shift, .alt]),     // xterm, lxterm
        "\u{1b}[1;6H": Key(.home, modifiers: [.ctrl, .shift]),            // xterm, lxterm
        "\u{1b}[1;8H": Key(.home, modifiers: [.ctrl, .shift, .alt]), // xterm, lxterm

        "\u{1b}[4~":   Key(.end),
        "\u{1b}[F":    Key(.end),                     // xterm, lxterm
        "\u{1b}[1;2F": Key(.end, modifiers: .shift),                // xterm, lxterm
        "\u{1b}[1;3F": Key(.end, modifiers: .alt),          // xterm, lxterm
        "\u{1b}[1;4F": Key(.end, modifiers: [.shift, .alt]),     // xterm, lxterm
        "\u{1b}[1;5F": Key(.end, modifiers: .ctrl),                 // xterm, lxterm
        "\u{1b}[1;6F": Key(.end, modifiers: [.ctrl, .shift]),            // xterm, lxterm
        "\u{1b}[1;7F": Key(.end, modifiers: [.ctrl, .alt]),      // xterm, lxterm
        "\u{1b}[1;8F": Key(.end, modifiers: [.ctrl, .shift, .alt]), // xterm, lxterm

        "\u{1b}[7~": Key(.home),          // urxvt
        "\u{1b}[7^": Key(.home, modifiers: .ctrl),      // urxvt
        "\u{1b}[7$": Key(.home, modifiers: .shift),     // urxvt
        "\u{1b}[7@": Key(.home, modifiers: [.ctrl, .shift]), // urxvt

        "\u{1b}[8~": Key(.end),          // urxvt
        "\u{1b}[8^": Key(.end, modifiers: .ctrl),      // urxvt
        "\u{1b}[8$": Key(.end, modifiers: .shift),     // urxvt
        "\u{1b}[8@": Key(.end, modifiers: [.ctrl, .shift]), // urxvt

        // Function keys, Linux console
        "\u{1b}[[A": Key(.f1), // linux console
        "\u{1b}[[B": Key(.f2), // linux console
        "\u{1b}[[C": Key(.f3), // linux console
        "\u{1b}[[D": Key(.f4), // linux console
        "\u{1b}[[E": Key(.f5), // linux console

        // Function keys, X11
        "\u{1b}OP": Key(.f1), // vt100, xterm
        "\u{1b}OQ": Key(.f2), // vt100, xterm
        "\u{1b}OR": Key(.f3), // vt100, xterm
        "\u{1b}OS": Key(.f4), // vt100, xterm

        "\u{1b}[1;3P": Key(.f1, modifiers: .alt), // vt100, xterm
        "\u{1b}[1;3Q": Key(.f2, modifiers: .alt), // vt100, xterm
        "\u{1b}[1;3R": Key(.f3, modifiers: .alt), // vt100, xterm
        "\u{1b}[1;3S": Key(.f4, modifiers: .alt), // vt100, xterm

        "\u{1b}[11~": Key(.f1), // urxvt
        "\u{1b}[12~": Key(.f2), // urxvt
        "\u{1b}[13~": Key(.f3), // urxvt
        "\u{1b}[14~": Key(.f4), // urxvt
        "\u{1b}[15~": Key(.f5), // vt100, xterm, also urxvt

        "\u{1b}[17~": Key(.f6),  // vt100, xterm, also urxvt
        "\u{1b}[18~": Key(.f7),  // vt100, xterm, also urxvt
        "\u{1b}[19~": Key(.f8),  // vt100, xterm, also urxvt
        "\u{1b}[20~": Key(.f9),  // vt100, xterm, also urxvt
        "\u{1b}[21~": Key(.f10), // vt100, xterm, also urxvt

        "\u{1b}[23~": Key(.f11), // vt100, xterm, also urxvt
        "\u{1b}[24~": Key(.f12), // vt100, xterm, also urxvt
        "\u{1b}[25~": Key(.f13), // vt100, xterm, also urxvt
        "\u{1b}[26~": Key(.f14), // vt100, xterm, also urxvt

        "\u{1b}[28~": Key(.f15), // vt100, xterm, also urxvt
        "\u{1b}[29~": Key(.f16), // vt100, xterm, also urxvt

        "\u{1b}[31~": Key(.f17),
        "\u{1b}[32~": Key(.f18),
        "\u{1b}[33~": Key(.f19),
        "\u{1b}[34~": Key(.f20),

        "\u{1b}[1;2P": Key(.f13),
        "\u{1b}[1;2Q": Key(.f14),
        "\u{1b}[1;2R": Key(.f15),
        "\u{1b}[1;2S": Key(.f16),

        "\u{1b}[15;2~": Key(.f17),
        "\u{1b}[17;2~": Key(.f18),
        "\u{1b}[18;2~": Key(.f19),
        "\u{1b}[19;2~": Key(.f20),

        "\u{1b}[15;3~": Key(.f5, modifiers: .alt), // vt100, xterm, also urxvt
        "\u{1b}[17;3~": Key(.f6, modifiers: .alt),  // vt100, xterm
        "\u{1b}[18;3~": Key(.f7, modifiers: .alt),  // vt100, xterm
        "\u{1b}[19;3~": Key(.f8, modifiers: .alt),  // vt100, xterm
        "\u{1b}[20;3~": Key(.f9, modifiers: .alt),  // vt100, xterm
        "\u{1b}[21;3~": Key(.f10, modifiers: .alt), // vt100, xterm

        "\u{1b}[23;3~": Key(.f11, modifiers: .alt), // vt100, xterm
        "\u{1b}[24;3~": Key(.f12, modifiers: .alt), // vt100, xterm
        "\u{1b}[25;3~": Key(.f13, modifiers: .alt), // vt100, xterm
        "\u{1b}[26;3~": Key(.f14, modifiers: .alt), // vt100, xterm

        "\u{1b}[28;3~": Key(.f15, modifiers: .alt), // vt100, xterm
        "\u{1b}[29;3~": Key(.f16, modifiers: .alt), // vt100, xterm

        // Powershell sequences.
        "\u{1b}OA": Key(.up),
        "\u{1b}OB": Key(.down),
        "\u{1b}OC": Key(.right),
        "\u{1b}OD": Key(.left),
    ]

    // All possible valid prefixes of escape sequences.
    nonisolated static private let prefixes = { () -> Set<String> in
        var result = Set<String>()
        for m in mapping.keys {
            var p = ""
            for c in m.dropLast() {
                p.append(String(c))
                result.insert(p)
            }
        }

        return result
    }()

    private func parse(continuation: AsyncThrowingStream<Key, Error>.Continuation) async throws {

        func timeout(_ state: State, yielding: String) -> (State, Timeout) {
            return (
                state,
                Task {
                    do {
                        try await Task.sleep(for: .milliseconds(30))

                        if !Task.isCancelled, self.state.state == state {
                            yield(string: yielding)
                        }
                    } catch is CancellationError {
                        // no timeout necessary.
                    } catch {
                        // Are there other possible errors here?
                    }
                }
            )
        }

        func yield(character: Unicode.Scalar) {
            state = (.initial, nil)
            continuation.yield(Key(.char(character)))
        }

        func yield(key: Key.Value, modifiers: Key.Modifiers = []) {
            state = (.initial, nil)
            continuation.yield(Key(key, modifiers: modifiers))
        }

        func yield(key: Key) {
            state = (.initial, nil)
            continuation.yield(key)
        }

        func yield(string: String) {
            state = (.initial, nil)
            for char in string.unicodeScalars { yield(character: char) }
        }

        for try await character in unicodeScalars {
            if let timeout = state.timeout {
                timeout.cancel()
            }

            switch (state.state, character) {
            case (.initial, "\u{1b}"):
                // We received an escape (^[) character, we need to wait a small amount of time for the next character to come in
                // before we emit an escape key that was received.
                state = timeout(.escape, yielding: "\u{1b}")

            case (.initial, let character):
                yield(character: character)

            case (.escape, "["): // ^[[
                state = timeout(.escapeSquareBracket, yielding: "\u{1b}[")
            case (.escape, "O"): // ^[O
                state = timeout(.escapeO, yielding: "\u{1b}O")
            case let (.escape, char):
                yield(string: "\u{1b}\(char)")

            case (.escapeO, "P"): yield(key: .f1)
            case (.escapeO, "Q"): yield(key: .f2)
            case (.escapeO, "R"): yield(key: .f3)
            case (.escapeO, "S"): yield(key: .f4)
            case (.escapeO, "A"): yield(key: .up)
            case (.escapeO, "B"): yield(key: .down)
            case (.escapeO, "C"): yield(key: .right)
            case (.escapeO, "D"): yield(key: .left)
            case let (.escapeO, char): yield(string: "\u{1b}O\(char)")

            case (.escapeSquareBracket, "A"): yield(key: .up)
            case (.escapeSquareBracket, "B"): yield(key: .down)
            case (.escapeSquareBracket, "C"): yield(key: .right)
            case (.escapeSquareBracket, "D"): yield(key: .left)
            case (.escapeSquareBracket, "Z"): yield(key: .tab, modifiers: .shift)
            case (.escapeSquareBracket, "H"): yield(key: .home)
            case (.escapeSquareBracket, "F"): yield(key: .end)

            case let (.escapeSquareBracket, value) where Digit ~= value:
                state = timeout(
                    .escapeSquareBracketDigit(Int(value.value - 0x30)),
                    yielding: "\u{1b}[\(value)"
                )
            case (.escapeSquareBracket, "<"):
                state = timeout(
                    .escapeSquareBracketLessThan,
                    yielding: "\u{1b}[<"
                )
            case let (.escapeSquareBracket, value):
                yield(string: "\u{1b}[\(value)")

            case (.escapeSquareBracketDigit(1), "~"):  yield(key: .home)
            case (.escapeSquareBracketDigit(2), "~"):  yield(key: .insert)
            case (.escapeSquareBracketDigit(3), "~"):  yield(key: .delete)
            case (.escapeSquareBracketDigit(4), "~"):  yield(key: .end)
            case (.escapeSquareBracketDigit(5), "~"):  yield(key: .pageUp)
            case (.escapeSquareBracketDigit(5), "^"):  yield(key: .pageUp, modifiers: .ctrl)
            case (.escapeSquareBracketDigit(6), "~"):  yield(key: .pageDown)
            case (.escapeSquareBracketDigit(6), "^"):  yield(key: .pageDown, modifiers: .ctrl)
            case (.escapeSquareBracketDigit(7), "~"):  yield(key: .home)
            case (.escapeSquareBracketDigit(7), "^"):  yield(key: .home, modifiers: .ctrl)
            case (.escapeSquareBracketDigit(7), "$"):  yield(key: .home, modifiers: .shift)
            case (.escapeSquareBracketDigit(7), "@"):  yield(key: .home, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigit(8), "~"):  yield(key: .end)
            case (.escapeSquareBracketDigit(8), "^"):  yield(key: .end, modifiers: .ctrl)
            case (.escapeSquareBracketDigit(8), "$"):  yield(key: .end, modifiers: .shift)
            case (.escapeSquareBracketDigit(8), "@"):  yield(key: .end, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigit(11), "~"): yield(key: .f1)
            case (.escapeSquareBracketDigit(12), "~"): yield(key: .f2)
            case (.escapeSquareBracketDigit(13), "~"): yield(key: .f3)
            case (.escapeSquareBracketDigit(14), "~"): yield(key: .f4)
            case (.escapeSquareBracketDigit(15), "~"): yield(key: .f5)
            case (.escapeSquareBracketDigit(17), "~"): yield(key: .f6)
            case (.escapeSquareBracketDigit(18), "~"): yield(key: .f7)
            case (.escapeSquareBracketDigit(19), "~"): yield(key: .f8)
            case (.escapeSquareBracketDigit(20), "~"): yield(key: .f9)
            case (.escapeSquareBracketDigit(21), "~"): yield(key: .f10)
            case (.escapeSquareBracketDigit(23), "~"): yield(key: .f11)
            case (.escapeSquareBracketDigit(24), "~"): yield(key: .f12)
            case (.escapeSquareBracketDigit(25), "~"): yield(key: .f13)
            case (.escapeSquareBracketDigit(26), "~"): yield(key: .f14)
            case (.escapeSquareBracketDigit(28), "~"): yield(key: .f15)
            case (.escapeSquareBracketDigit(29), "~"): yield(key: .f16)
            case (.escapeSquareBracketDigit(31), "~"): yield(key: .f17)
            case (.escapeSquareBracketDigit(32), "~"): yield(key: .f18)
            case (.escapeSquareBracketDigit(33), "~"): yield(key: .f19)
            case (.escapeSquareBracketDigit(34), "~"): yield(key: .f20)

            case let (.escapeSquareBracketDigit(digit), ";"):
                state = timeout(
                    .escapeSquareBracketDigitSemicolon(digit),
                    yielding: "\u{1b}[\(digit);"
                )
            case let (.escapeSquareBracketDigit(digit), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketDigit(digit * 10 + Int(char.value - 0x30)),
                    yielding: "\u{1b}[\(digit)\(char)"
                )
            case let (.escapeSquareBracketDigit(digit), char):
                yield(string: "\u{1b}[\(digit)\(char)")

            case let (.escapeSquareBracketDigitSemicolon(digit), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketDigitDigit(digit, Int(char.value - 0x30)),
                    yielding: "\u{1b}[\(digit);\(char)"
                )
            case let (.escapeSquareBracketDigitSemicolon(digit), char):
                yield(string: "\u{1b}[\(digit);\(char)")

            case (.escapeSquareBracketDigitDigit(1, 2), "A"): yield(key: .up, modifiers: .shift)
            case (.escapeSquareBracketDigitDigit(1, 2), "B"): yield(key: .down, modifiers: .shift)
            case (.escapeSquareBracketDigitDigit(1, 2), "C"): yield(key: .right, modifiers: .shift)
            case (.escapeSquareBracketDigitDigit(1, 2), "D"): yield(key: .left, modifiers: .shift)

            case (.escapeSquareBracketDigitDigit(1, 3), "A"): yield(key: .up, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "B"): yield(key: .down, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "C"): yield(key: .right, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "D"): yield(key: .left, modifiers: .alt)

            case (.escapeSquareBracketDigitDigit(1, 4), "A"): yield(key: .up, modifiers: [.shift, .alt])
            case (.escapeSquareBracketDigitDigit(1, 4), "B"): yield(key: .down, modifiers: [.shift, .alt])
            case (.escapeSquareBracketDigitDigit(1, 4), "C"): yield(key: .right, modifiers: [.shift, .alt])
            case (.escapeSquareBracketDigitDigit(1, 4), "D"): yield(key: .left, modifiers: [.shift, .alt])

            case (.escapeSquareBracketDigitDigit(1, 5), "A"): yield(key: .up, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(1, 5), "B"): yield(key: .down, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(1, 5), "C"): yield(key: .right, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(1, 5), "D"): yield(key: .left, modifiers: .ctrl)

            case (.escapeSquareBracketDigitDigit(1, 6), "A"): yield(key: .up, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigitDigit(1, 6), "B"): yield(key: .down, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigitDigit(1, 6), "C"): yield(key: .right, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigitDigit(1, 6), "D"): yield(key: .left, modifiers: [.ctrl, .shift])

            case (.escapeSquareBracketDigitDigit(1, 7), "A"): yield(key: .up, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 7), "B"): yield(key: .down, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 7), "C"): yield(key: .right, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 7), "D"): yield(key: .left, modifiers: [.ctrl, .alt])

            case (.escapeSquareBracketDigitDigit(1, 8), "A"): yield(key: .up, modifiers: [.ctrl, .alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 8), "B"): yield(key: .down, modifiers: [.ctrl, .alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 8), "C"): yield(key: .right, modifiers: [.ctrl, .alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 8), "D"): yield(key: .left, modifiers: [.ctrl, .alt, .shift])

            case (.escapeSquareBracketDigitDigit(3, 2), "~"): yield(key: .insert)
            case (.escapeSquareBracketDigitDigit(3, 3), "~"): yield(key: .delete)
            case (.escapeSquareBracketDigitDigit(3, 5), "~"): yield(key: .delete, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(5, 3), "~"): yield(key: .pageUp, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(5, 5), "~"): yield(key: .pageUp, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(5, 7), "~"): yield(key: .pageUp, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 2), "H"): yield(key: .home, modifiers: .shift)
            case (.escapeSquareBracketDigitDigit(1, 3), "H"): yield(key: .home, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 4), "H"): yield(key: .home, modifiers: [.alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 5), "H"): yield(key: .home, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(1, 6), "H"): yield(key: .home, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigitDigit(1, 7), "H"): yield(key: .home, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 8), "H"): yield(key: .home, modifiers: [.ctrl, .alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 2), "F"): yield(key: .end, modifiers: .shift)
            case (.escapeSquareBracketDigitDigit(1, 3), "F"): yield(key: .end, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 4), "F"): yield(key: .end, modifiers: [.alt, .shift])
            case (.escapeSquareBracketDigitDigit(1, 5), "F"): yield(key: .end, modifiers: .ctrl)
            case (.escapeSquareBracketDigitDigit(1, 6), "F"): yield(key: .end, modifiers: [.ctrl, .shift])
            case (.escapeSquareBracketDigitDigit(1, 7), "F"): yield(key: .end, modifiers: [.ctrl, .alt])
            case (.escapeSquareBracketDigitDigit(1, 8), "F"): yield(key: .end, modifiers: [.ctrl, .alt, .shift])

            case (.escapeSquareBracketDigitDigit(1, 3), "P"): yield(key: .f1, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "Q"): yield(key: .f2, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "R"): yield(key: .f3, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(1, 3), "S"): yield(key: .f4, modifiers: .alt)

            case (.escapeSquareBracketDigitDigit(1, 2), "P"): yield(key: .f13)
            case (.escapeSquareBracketDigitDigit(1, 2), "Q"): yield(key: .f14)
            case (.escapeSquareBracketDigitDigit(1, 2), "R"): yield(key: .f15)
            case (.escapeSquareBracketDigitDigit(1, 2), "S"): yield(key: .f16)

            case (.escapeSquareBracketDigitDigit(15, 2), "~"): yield(key: .f17)
            case (.escapeSquareBracketDigitDigit(16, 2), "~"): yield(key: .f18)
            case (.escapeSquareBracketDigitDigit(17, 2), "~"): yield(key: .f19)
            case (.escapeSquareBracketDigitDigit(18, 2), "~"): yield(key: .f20)

            case (.escapeSquareBracketDigitDigit(15, 3), "~"): yield(key: .f5, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(17, 3), "~"): yield(key: .f6, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(18, 3), "~"): yield(key: .f7, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(19, 3), "~"): yield(key: .f8, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(20, 3), "~"): yield(key: .f9, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(21, 3), "~"): yield(key: .f10, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(23, 3), "~"): yield(key: .f11, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(24, 3), "~"): yield(key: .f12, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(25, 3), "~"): yield(key: .f13, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(26, 3), "~"): yield(key: .f14, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(28, 3), "~"): yield(key: .f15, modifiers: .alt)
            case (.escapeSquareBracketDigitDigit(29, 3), "~"): yield(key: .f16, modifiers: .alt)
            case let (.escapeSquareBracketDigitDigit(digit1, digit2), char):
                yield(string: "\u{1b}[\(digit1);\(digit2)\(char)")

            case let (.escapeSquareBracketLessThan, char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigit(Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(char)"
                )
            case let (.escapeSquareBracketLessThan, char): yield(string: "\u{1b}[<\(char)")

            case let (.escapeSquareBracketLessThanDigit(digit), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigit(digit * 10 + Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(digit)\(char)"
                )
            case let (.escapeSquareBracketLessThanDigit(digit), ";"):
                state = timeout(
                    .escapeSquareBracketLessThanDigitSemicolon(digit),
                    yielding: "\u{1b}[<\(digit);"
                )
            case let (.escapeSquareBracketLessThanDigit(digit), char):
                yield(string: "\u{1b}[<\(digit)\(char)")

            case let (.escapeSquareBracketLessThanDigitSemicolon(digit), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigitDigit(digit, Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(digit);\(char)"
                )
            case let (.escapeSquareBracketLessThanDigitSemicolon(digit), char):
                yield(string: "\u{1b}[<\(digit);\(char)")

            case let (.escapeSquareBracketLessThanDigitDigit(digit1, digit2), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigitDigit(digit1, digit2 * 10 + Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(digit1);\(digit2)\(char)"
                )
            case let (.escapeSquareBracketLessThanDigitDigit(digit1, digit2), ";"):
                state = timeout(
                    .escapeSquareBracketLessThanDigitDigitSemicolon(digit1, digit2),
                    yielding: "\u{1b}[<\(digit1);\(digit2);"
                )
            case let (.escapeSquareBracketLessThanDigitDigit(digit1, digit2), char):
                yield(string: "\u{1b}[<\(digit1);\(digit2)\(char)")

            case let (.escapeSquareBracketLessThanDigitDigitSemicolon(digit1, digit2), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigitDigitDigit(digit1, digit2, Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(digit1);\(char)"
                )
            case let (.escapeSquareBracketLessThanDigitDigitSemicolon(digit1, digit2), char):
                yield(string: "\u{1b}[<\(digit1);\(digit2)\(char)")

            case let (.escapeSquareBracketLessThanDigitDigitDigit(digit1, digit2, digit3), char) where Digit ~= char:
                state = timeout(
                    .escapeSquareBracketLessThanDigitDigitDigit(digit1, digit2, digit3 * 10 + Int(char.value - 0x30)),
                    yielding: "\u{1b}[<\(digit1);\(digit2);\(digit3)\(char)"
                )
            case let (.escapeSquareBracketLessThanDigitDigitDigit(digit1, digit2, digit3), char):
                if let key = Key.fromMouseEvent(
                    mouse: digit1,
                    position: .init(
                        column: Extended(digit2),
                        line: Extended(digit3)
                    ),
                    suffix: char
                ) {
                    yield(key: key)
                } else {
                    yield(string: "\u{1b}[\(digit1);\(digit2);\(digit3)\(char)")
                }
            }
        }

    }
}

private let Digit = Unicode.Scalar(0x30)...Unicode.Scalar(0x39)
