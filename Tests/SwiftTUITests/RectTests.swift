//
//  RectTests.swift
//  SwiftTUI
//
//  Created by Peter Kovacs on 1/6/25.
//

@testable import SwiftTUI
import Testing

@Test func testRectUnionWithZero() async throws {
    let rect = Rect(column: 50, line: 50, width: 100, height: 100)
    #expect(rect.union(.zero) == rect)
}

@Test func testRectUnionWithNonZero() async throws {
    let rect = Rect(column: 50, line: 50, width: 100, height: 100)
    #expect(rect.union(.init(column: 0, line: 0, width: 10, height: 10)) == .init(column: 0, line: 0, width: 150, height: 150))
}
