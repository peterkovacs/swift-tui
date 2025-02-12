import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("TextField Tests", .snapshots(record: .missing))
struct TextFieldTests {
    @Test func testOverflowFrame() async throws {
        struct MyView: View {
            @State var text: String = ""
            var body: some View {
                TextField("Placeholder Text", text: $text) { _ in }
                    .frame(width: 20)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        application.process(keys: "This is some text it is going to overflow the text field.")

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }
}
