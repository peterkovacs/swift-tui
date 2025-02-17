import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("TextField Tests", .snapshots(record: .missing)) struct TextFieldTests {
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

    @Test func textFieldInFrame() async throws {
        struct MyView: View {
            @State var text: String = ""
            var body: some View {
                TextField("Placeholder Text", text: $text) { _ in }
                    .frame(width: 30)
                    .border()
                    .frame(width: 60)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 62x5
              → ComposedView<MyView>
                → Border:[(0, 0) 62x5]
                  → FixedFrame:60x(nil) [60x3]
                    → Border:[(15, 1) 32x3]
                      → FixedFrame:30x(nil) [30x1]
                        → TextField:"" (0) FOCUSED (16, 2) 30x1

            """
        }
        assertSnapshot(of: application.renderer, as: .rendered)

        application.process(keys: "Hello World")
        assertSnapshot(of: application.renderer, as: .rendered)
    }
}
