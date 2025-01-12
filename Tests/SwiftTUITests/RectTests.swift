//
//  RectTests.swift
//  SwiftTUI
//
//  Created by Peter Kovacs on 1/6/25.
//

@testable import SwiftTUI
import Testing

@Suite("Rect Tests") struct RectTests {
    @Test func testRectUnionWithZero() async throws {
        let rect = Rect(column: 50, line: 50, width: 100, height: 100)
        #expect(rect.union(.zero) == rect)
    }

    @Test func testRectUnionWithNonZero() async throws {
        let rect = Rect(column: 50, line: 50, width: 100, height: 100)
        #expect(rect.union(.init(column: 0, line: 0, width: 10, height: 10)) == .init(column: 0, line: 0, width: 150, height: 150))
    }

    @Test func testRectIntersectionWithZero() async throws {
        let rect = Rect(column: 50, line: 50, width: 100, height: 100)
        #expect(rect.intersection(.zero) == rect)
        #expect(.zero.intersection(rect) == rect)
    }

    @Test func testRectIntersectionWithOverlapping() async throws {
        let a = Rect(column: 50, line: 50, width: 100, height: 100)
        let b = Rect(column: 0, line: 0, width: 60, height: 60)

        #expect(a.intersection(b) == .init(column: 50, line: 50, width: 10, height: 10))
        #expect(b.intersection(a) == .init(column: 50, line: 50, width: 10, height: 10))
    }

    @Test func testRectIntersectionContaining() async throws {
        let a = Rect(column: 50, line: 50, width: 100, height: 100)
        let b = Rect(column: 55, line: 55, width: 30, height: 30)

        #expect(a.intersection(b) == b)
        #expect(b.intersection(a) == b)
    }

    @Test func testRectIntersectionWithTouching() async throws {
        do {
            // Touching on corner
            let a = Rect(column: 50, line: 50, width: 100, height: 100)
            let b = Rect(column: 0, line: 0, width: 50, height: 50)

            #expect(a.intersection(b) == nil)
            #expect(b.intersection(a) == nil)
        }

        do {
            // Touching on edge.
            let a = Rect(column: 50, line: 50, width: 100, height: 100)
            let b = Rect(column: 0, line: 0, width: 50, height: 100)

            #expect(a.intersection(b) == nil)
            #expect(b.intersection(a) == nil)
        }
    }

    @Test func testRectIntersectionWithNotOverlapping() async throws {
        let a = Rect(column: 50, line: 50, width: 100, height: 100)
        let b = Rect(column: 0, line: 0, width: 10, height: 10)

        #expect(a.intersection(b) == nil)
        #expect(b.intersection(a) == nil)
    }

    @Test func testClampedInfinity() async throws {
        do {
            let a = Rect(column: 0, line: 0, width: .infinity, height: 100)
            let b = Rect(column: 0, line: 0, width: 100, height: 100)

            #expect(a.clamped(to: b) == b)
            #expect(b.clamped(to: a) == b)
        }

        do {
            let a = Rect(column: 0, line: 0, width: .infinity, height: 50)
            let b = Rect(column: 0, line: 0, width: 100, height: 100)

            #expect(a.clamped(to: b) == .init(position: .zero, size: .init(width: 100, height: 50)))
            #expect(b.clamped(to: a) == b)
        }

        do {
            let a = Rect(column: 0, line: 0, width: 100, height: .infinity)
            let b = Rect(column: 0, line: 0, width: 100, height: 100)

            #expect(a.clamped(to: b) == b)
            #expect(b.clamped(to: a) == b)
        }

        do {
            let a = Rect(column: 0, line: 0, width: 50, height: .infinity)
            let b = Rect(column: 0, line: 0, width: 100, height: 100)

            #expect(a.clamped(to: b) == .init(position: .zero, size: .init(width: 50, height: 100)))
            #expect(b.clamped(to: a) == b)
        }

    }
}
