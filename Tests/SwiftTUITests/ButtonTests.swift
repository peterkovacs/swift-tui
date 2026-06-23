import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing
import Synchronization

@MainActor @Suite("Button Tests", .snapshots(record: .failed)) struct ButtonTests {
    @Test func testDisabledButtonSkippedForDefaultFocus() async throws {
        struct MyView: View {
            var body: some View {
                Button("Disabled") { }
                    .disabled()
                Button("Enabled") { }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 8x2
              → ComposedView<MyView>
                → TupleView<Pack{SetEnvironmentView<Button<Text>, Bool>, Button<Text>}>
                  → SetEnvironmentView<Button<Text>, Bool>
                    → Button (0, 0) 8x1
                      → Text:string("Disabled") (0, 0) 8x1
                  → Button FOCUSED (0, 1) 7x1
                    → Text:string("Enabled") (0, 1) 7x1

            """
        }
    }

    @Test func testDisabledButtonDoesNotFireAction() async throws {
        let actionCalled = Mutex(false)

        struct MyView: View {
            let action: @MainActor () -> Void
            var body: some View {
                Button("Go", action: action)
                    .disabled()
            }
        }

        let (application, _) = try drawView(MyView { actionCalled.withLock { $0 = true } })

        // No focusable element, so keypress goes nowhere
        application.process(key: .init(.enter))
        application.process(key: .init(.space))

        #expect(actionCalled.withLock(\.self) == false)
    }


    @Test func containsImplicitHStack() async throws {
        struct MyView: View {
            let action: @MainActor () -> Void
            var body: some View {
                Button(action: action) {
                    Text("Hello")
                    Text("World")
                        .frame(height: 3)
                }
            }
        }

        let actionCalled = Mutex(false)
        let (application, _) = try drawView(MyView { actionCalled.withLock { $0.toggle() } })

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 11x3
              → ComposedView<MyView>
                → Button FOCUSED (0, 0) 11x3
                  → TupleView<Pack{Text, FixedFrame<Text>}>
                    → Text:string("Hello") (0, 1) 5x1
                    → FixedFrame:(nil)x3 [5x3]
                      → Text:string("World") (6, 1) 5x1

            """
        }
        assertSnapshot(of: application.renderer, as: .rendered)

        #expect(actionCalled.withLock(\.self) == false)
        application.process(key: .init(.enter))
        #expect(actionCalled.withLock(\.self) == true)
    }

    @Test func testHitTest() async throws {
        struct MyView: View {
            var body: some View {
                Button {

                } label: {
                    Text("Hello World")
                        .frame(width: 30)
                }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 30x1
              → ComposedView<MyView>
                → Button FOCUSED (0, 0) 30x1
                  → FixedFrame:30x(nil) [30x1]
                    → Text:string("Hello World") (9, 0) 11x1

            """
        }
        assertInlineSnapshot(of: application.node.hitTest(at: .init(column: 0, line: 0), key: .init(.mouseUp(button: 0, at: .zero))), as: .frameDescription) {
            """
            → Button FOCUSED (0, 0) 30x1
              → FixedFrame:30x(nil) [30x1]
                → Text:string("Hello World") (9, 0) 11x1

            """
        }
    }
}
