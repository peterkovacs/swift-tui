import Foundation
@testable import SwiftTUI
import SnapshotTesting

class TestRenderer: Renderer {
    var window: Window<Cell?>
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

extension SimplySnapshotting where Value == Application, Format == String {
    @MainActor static let frameDescription = SimplySnapshotting.lines.pullback(\Application.node.frameDescription)
}

extension Snapshotting where Value == Renderer?, Format == String {
    @MainActor static let rendered = Snapshotting(
        pathExtension: "txt",
        diffing: .lines
    ) { value in
        guard let renderer = value as? TestRenderer else {
            fatalError("Renderer was not a TestRenderer")
        }

        return renderer.description
    }

    @MainActor static let attributes = Snapshotting(
        pathExtension: "txt",
        diffing: .lines
    ) { value in
        guard let renderer = value as? TestRenderer else {
            fatalError("Renderer was not a TestRenderer")
        }

        var result = ""

        for y in 0..<renderer.window.size.height.intValue {
            for x in 0..<renderer.window.size.width.intValue {
                let attributes = renderer.window[
                        .init(
                            column: Extended(x),
                            line: Extended(y)
                        )
                    ]?.attributes

                if let attributes {
                    if attributes.bold {
                        result.append("B")
                    } else if attributes.italic {
                        result.append("I")
                    } else if attributes.strikethrough {
                        result.append("S")
                    } else if attributes.underline {
                        result.append("U")
                    } else if attributes.inverted {
                        result.append("X")
                    } else {
                        result.append(" ")
                    }
                } else {
                    result.append(" ")
                }
            }

            result.append("\n")
        }

        return result
    }

    @MainActor static let background = Snapshotting(
        pathExtension: "txt",
        diffing: .lines
    ) { value in
        guard let renderer = value as? TestRenderer else {
            fatalError("Renderer was not a TestRenderer")
        }

        var result = ""

        for y in 0..<renderer.window.size.height.intValue {
            for x in 0..<renderer.window.size.width.intValue {
                let backgroundColor = renderer.window[
                    .init(
                        column: Extended(x),
                        line: Extended(y)
                    )
                ]?.backgroundColor

                switch backgroundColor {
                case .black: result.append("K")
                case .red: result.append("R")
                case .green: result.append("G")
                case .yellow: result.append("Y")
                case .blue: result.append("B")
                case .magenta: result.append("M")
                case .cyan: result.append("C")
                case .white: result.append("⬜️")
                default: result.append(" ")
                }
            }

            result.append("\n")
        }

        return result
    }

}

