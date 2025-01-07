//
//  TestRenderer.swift
//  SwiftTUI
//
//  Created by Peter Kovacs on 1/6/25.
//

import Foundation
@testable import SwiftTUI

class TestRenderer: Renderer {
    var window: CellGrid<Cell?>
    var size: Size = .zero
    var invalidated: Rect?
    weak var application: Application?

    init(size: Size) {
        self.window = .init(repeating: nil, size: size)
        self.size = size
    }

    func setSize() {
        window = .init(repeating: nil, size: size)
    }

    func drawPixel(_ cell: Cell?, at position: Position) {
        window[position] = cell
    }

    func stop() {
        // noop
    }

    var description: String {
        draw(rect: nil)
        return window.map { $0?.char ?? " " }.description
    }
}

@MainActor
func drawView<V: View>(_ view: V, size: Size = .init(width: 100, height: 100)) throws -> (Application, FileHandle) {
    let (parser, fileHandle) = KeyParser.pipe()
    let application = Application(
        root: view,
        renderer: TestRenderer(size: size),
        parser: parser
    )

    application.setup()

    return (application, fileHandle)
}

extension KeyParser {
    static func pipe() -> (parser: KeyParser, fileHandle: FileHandle) {
        let pipe = Pipe()
        let parser = KeyParser(fileHandle: pipe.fileHandleForReading)

        return (parser: parser, fileHandle: pipe.fileHandleForWriting)
    }
}
