import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("TextField Tests", .snapshots(record: .missing)) struct TextFieldTests {
    @Test func testDeleteKeyForwardDeletes() async throws {
        struct MyView: View {
            @State var text = ""
            var body: some View {
                TextField(text: $text) { _ in }
            }
        }

        let (application, _) = try drawView(MyView())
        application.process(keys: "Hello")

        // Move cursor to start, then forward-delete the first character
        application.process(key: .init(.left, modifiers: .ctrl))
        application.process(key: .init(.delete))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x1
              → ComposedView<MyView>
                → TextField:"ello" (0) FOCUSED (0, 0) 100x1

            """
        }
    }

    @Test func testDeleteKeyDoesNothingAtEndOfText() async throws {
        struct MyView: View {
            @State var text = ""
            var body: some View {
                TextField(text: $text) { _ in }
            }
        }

        let (application, _) = try drawView(MyView())
        application.process(keys: "Hello")
        // Cursor is at end; Delete should do nothing
        application.process(key: .init(.delete))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x1
              → ComposedView<MyView>
                → TextField:"Hello" (5) FOCUSED (0, 0) 100x1

            """
        }
    }

    @Test func testPlaceholderFirstCharHighlightedWhenFocused() async throws {
        struct MyView: View {
            @State var text = ""
            var body: some View {
                TextField("ABCDE", text: $text) { _ in }
            }
        }

        // Use a 5-wide, 1-tall window so the placeholder exactly fills the frame
        let (application, _) = try drawView(MyView(), size: .init(width: 5, height: 1))

        let renderer = application.renderer as! TestRenderer
        // First placeholder character should be inverted (cursor highlight)
        #expect(renderer.window[.init(column: 0, line: 0)]?.attributes.inverted == true)
        // Remaining placeholder characters should NOT be inverted
        for col in 1..<5 {
            #expect(renderer.window[.init(column: Extended(col), line: 0)]?.attributes.inverted == false)
        }
    }

    @Test func testDisabledTextFieldSkippedForDefaultFocus() async throws {
        struct MyView: View {
            @State var text1 = ""
            @State var text2 = ""
            var body: some View {
                TextField(text: $text1) { _ in }
                    .disabled()
                TextField(text: $text2) { _ in }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x2
              → ComposedView<MyView>
                → TupleView<Pack{SetEnvironmentView<TextField, Bool>, TextField}>
                  → SetEnvironmentView<TextField, Bool>
                    → TextField:"" (0) (0, 0) 100x1
                  → TextField:"" (0) FOCUSED (0, 1) 100x1

            """
        }
    }

    @Test func testDisabledTextFieldDoesNotAcceptInput() async throws {
        struct MyView: View {
            @State var text = ""
            var body: some View {
                // Only a disabled TextField: it should not receive focus or handle keys
                TextField(text: $text) { _ in }
                    .disabled()
            }
        }

        let (application, _) = try drawView(MyView())
        application.process(keys: "Hello")

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x1
              → ComposedView<MyView>
                → SetEnvironmentView<TextField, Bool>
                  → TextField:"" (0) (0, 0) 100x1

            """
        }
    }


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
