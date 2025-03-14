@testable import SwiftTUI
import Testing

@MainActor
@Suite("Background Tests") struct BackgroundTests {
    @Test func rendersBackground() throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello").bold()
                    Spacer()
                    Text("World").italic()
                }
                .background(.blue)

                Spacer()

                HStack {
                    Text("Goodbye").strikethrough()
                    Spacer()
                    Text("World").underline()
                }
                .background(.red)
            }
        }

        let (application, _) = try drawView(MyView())
        let blueCells = application.renderer.window.indices.filter { application.renderer.window[$0]?.backgroundColor == .blue }
        #expect(blueCells.count == 100)
        #expect(
            blueCells
                .allSatisfy { (0..<100).contains($0.column) && $0.line == 0 }
        )

        let redCells = application.renderer.window.indices.filter { application.renderer.window[$0]?.backgroundColor == .red }
        #expect(redCells.count == 100)
        #expect(
            redCells
                .allSatisfy { (0..<100).contains($0.column) && $0.line == 99 }
        )

    }

    @Test func testFixedFrameWithBackground() throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(width: 20, height: 20)
                    .background(.blue)
                Text("Goodbye World")
                    .frame(width: 20, height: 20)
                    .background(.red)
            }
        }
        
        let (application, _) = try drawView(MyView())
        let blueCells = application.renderer.window.indices.filter { application.renderer.window[$0]?.backgroundColor == .blue }
        #expect(blueCells.count == 400)
        #expect(
            blueCells == Array(Rect(column: 0, line: 0, width: 20, height: 20).indices)
        )

        let redCells = application.renderer.window.indices.filter { application.renderer.window[$0]?.backgroundColor == .red }
        #expect(redCells.count == 400)
        #expect(
            redCells == Array(Rect(column: 0, line: 20, width: 20, height: 20).indices)
        )

    }
}
