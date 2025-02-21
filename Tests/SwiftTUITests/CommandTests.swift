import InlineSnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Command Tests", .snapshots(record: .missing)) struct CommandTests {
    @Test func interceptsAndCallsActionWhenChildIsFocused() async throws {
        struct MyView: View {
            @State var text: String = ""
            let action: () -> Void

            var body: some View {
                TextField(text: $text) { _ in }
                    .command(.init("w", modifiers: .ctrl)) {
                        action()
                    }
            }
        }

        var called = false
        let (application, _) = try drawView(MyView {
            called.toggle()
        })

        application.process(keys: "Hello World")
        application.process(key: .init("w", modifiers: .ctrl))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x1
              → ComposedView<MyView>
                → Command<TextField>
                  → TextField:"Hello World" (11) FOCUSED (0, 0) 100x1

            """
        }
        #expect(called)
    }

    @Test func isNotCalledWhenNotFocused() async throws {
        struct MyView: View {
            @State var text1: String = ""
            @State var text2: String = ""
            let action: () -> Void

            var body: some View {
                TextField(text: $text1) { _ in }
                TextField(text: $text2) { _ in }
                    .command(.init("w", modifiers: .ctrl)) {
                        action()
                    }
            }
        }

        var called = false
        let (application, _) = try drawView(MyView {
            called.toggle()
        })

        application.process(keys: "Hello World")
        application.process(key: .init("w", modifiers: .ctrl))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x2
              → ComposedView<MyView>
                → TupleView<Pack{TextField, Command<TextField>}>
                  → TextField:"Hello " (6) FOCUSED (0, 0) 100x1
                  → Command<TextField>
                    → TextField:"" (0) (0, 1) 100x1

            """
        }
        #expect(!called)
    }
}
