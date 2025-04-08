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

            ("[<0;100;29M", Key(.mouseDown(button: 0, at: .init(column: 100, line: 29)))),
        ]
    )
    func parsesEscapeSequences(input: String, expectation: Key) async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = parser.makeAsyncIterator()

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
        var iterator = parser.makeAsyncIterator()

        Task {
            try fileHandle.write(
                contentsOf: "\u{1b}[<0;100;29M".data(using: .utf8)!
            )
        }

        let key = try await iterator.next()
        #expect(key == Key(.mouseDown(button: 0, at: .init(column: 100, line: 29))))

    }

    @Test func parsesF5() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = parser.makeAsyncIterator()
        
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
        var iterator = parser.makeAsyncIterator()

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

    @Test func parsesUnicode() async throws {
        let (parser, fileHandle) = KeyParser.pipe()
        var iterator = parser.makeAsyncIterator()

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
