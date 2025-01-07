import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite struct RendererTests {

    @Test func testRenders() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Spacer()

                    VStack {
                        Text("1234567890")
                        Spacer()
                        Text("1234567890")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 20, height: 5))
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines
        )
        #expect(
            (application.renderer as? TestRenderer)?.description ==
            "Hello     1234567890\n" +
            "                    \n" +
            "                    \n" +
            "                    \n" +
            "World     1234567890\n"
        )
    }
}
