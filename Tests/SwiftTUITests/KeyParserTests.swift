import Testing
import Foundation
@testable import SwiftTUI

@MainActor
@Suite("KeyParser")
struct KeyParserTests {
    @Test(
        arguments: [
            ("[1;2A", Key(.up, modifiers: .shift)),
            ("[1;2B", Key(.down, modifiers: .shift)),
            ("[1;2C", Key(.right, modifiers: .shift)),
            ("[1;2D", Key(.left, modifiers: .shift)),

            ("[1;5A", Key(.up, modifiers: .ctrl)),
            ("[1;5B", Key(.down, modifiers: .ctrl)),
            ("[1;5C", Key(.right, modifiers: .ctrl)),
            ("[1;5D", Key(.left, modifiers: .ctrl)),

            ("[11~", Key(.f1)),
            ("[12~", Key(.f2)),
            ("[13~", Key(.f3)),
            ("[14~", Key(.f4)),
            ("[15~", Key(.f5)),
            ("[17~", Key(.f6)),
            ("[18~", Key(.f7)),
            ("[19~", Key(.f8)),
            ("[20~", Key(.f9)),
            ("[21~", Key(.f10)),
            ("[23~", Key(.f11)),
            ("[24~", Key(.f12)),
            ("[25~", Key(.f13)),
            ("[26~", Key(.f14)),
            ("[28~", Key(.f15)),
            ("[29~", Key(.f16)),
            ("[31~", Key(.f17)),
            ("[32~", Key(.f18)),
            ("[33~", Key(.f19)),
            ("[34~", Key(.f20)),

            ("[1~", Key(.home)),
            ("[4~", Key(.end)),
            ("[5~", Key(.pageUp)),
            ("[6~", Key(.pageDown)),

            ("[<65;82;16M", Key(.mouseScrollDown(Position(column: 81, line: 15), delta: 1))),
            ("[<64;82;16M", Key(.mouseScrollUp(.init(column: 81, line: 15), delta: 1))),
            ("[<35;81;16M", Key(.mouseMove(.init(column: 80, line: 15)))),
            ("[<0;80;17M", Key(.mouseDown(button: 0, at: .init(column: 79, line: 16)))),
            ("[<0;80;17m", Key(.mouseUp(button: 0, at: .init(column: 79, line: 16)))),
            ("[<2;80;17M", Key(.mouseDown(button: 2, at: .init(column: 79, line: 16)))),
            ("[<2;80;17m", Key(.mouseUp(button: 2, at: .init(column: 79, line: 16)))),

            ("[<0;100;29M", Key(.mouseDown(button: 0, at: .init(column: 99, line: 28)))),
            ("[<30;80;17M", Key(.mouseDown(button: 2, at: .init(column: 79, line: 16)), modifiers: [.shift, .alt, .ctrl])),
        ]
    )
    func parsesEscapeSequences(input: String, expectation: Key) async throws {
        let (parser, fileHandle) = KeyParser.pipe()

        let sequence = await parser.parse()
        var iterator = sequence.makeAsyncIterator()

        Task {
            try fileHandle.write(
                contentsOf: "\u{1b}\(input)".data(using: .utf8)!
            )
        }

        let key = try await iterator.next()
        #expect(key == expectation)
    }

    @Test func parsesMouseDown() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = await parser.parse().makeAsyncIterator()

        Task {
            try fileHandle.write(
                contentsOf: "\u{1b}[<0;100;29M".data(using: .utf8)!
            )
        }

        let key = try await iterator.next()
        #expect(key == Key(.mouseDown(button: 0, at: .init(column: 99, line: 28))))

    }

    @Test func parsesF5() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = await parser.parse().makeAsyncIterator()
        
        Task {
            try fileHandle.write(
                contentsOf: "\u{1b}[15~".data(using: .utf8)!
            )
        }

        let key = try await iterator.next()
        #expect(key == Key(.f5))
    }

    @Test func parsesEscape() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = await parser.parse().makeAsyncIterator()

        Task {
            try fileHandle.write(
                contentsOf: "\u{1b}".data(using: .utf8)!
            )
            try await Task.sleep(for: .milliseconds(100))
            try fileHandle.write(
                contentsOf: "[".data(using: .utf8)!
            )

        }

        do {
            let key = try await iterator.next()
            #expect(key == Key(.escape))
        }

        do {
            let key = try await iterator.next()
            #expect(key == Key("["))
        }

    }

    // Verifies that the timeout yielding string for a partial 3-part mouse sequence
    // includes all three digit groups (digit1, digit2, and the start of digit3).
    // Before the fix the string was missing digit2, e.g. "\u{1b}[<1;3" instead of
    // "\u{1b}[<1;2;3", so the yielded key sequence was shorter and incorrect.
    @Test func testMouseSequenceTimeoutIncludesAllDigits() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = await parser.parse().makeAsyncIterator()

        // Write ESC [ < 1 ; 2 ; 3  (incomplete – missing the terminal M/m)
        Task {
            try fileHandle.write(contentsOf: "\u{1b}[<1;2;3".data(using: .utf8)!)
        }

        // Wait longer than the 30 ms parser timeout so the partial sequence is flushed
        try await Task.sleep(for: .milliseconds(150))

        // With the fix the string "\u{1b}[<1;2;3" is yielded as 8 individual char keys
        let k1 = try await iterator.next()
        let k2 = try await iterator.next()
        let k3 = try await iterator.next()
        let k4 = try await iterator.next()
        let k5 = try await iterator.next()
        let k6 = try await iterator.next()
        let k7 = try await iterator.next()
        let k8 = try await iterator.next()

        #expect(k1 == Key(.char("\u{1b}")))
        #expect(k2 == Key(.char("[")))
        #expect(k3 == Key(.char("<")))
        #expect(k4 == Key(.char("1")))
        #expect(k5 == Key(.char(";")))
        #expect(k6 == Key(.char("2"))) // was missing before the fix
        #expect(k7 == Key(.char(";"))) // was missing before the fix
        #expect(k8 == Key(.char("3")))
    }

    @Test func parsesUnicode() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = await parser.parse().makeAsyncIterator()

        Task {
            try fileHandle.write(
                contentsOf: "\u{1f468}".data(using: .utf8)!
            )
        }

        let key = try await iterator.next()
        #expect(key == .init(.char("\u{1f468}")))

    }
}

// Unicode: U+1F468, UTF-8: F0 9F 91 A8
// Unicode: U+1F469, UTF-8: F0 9F 91 A9
