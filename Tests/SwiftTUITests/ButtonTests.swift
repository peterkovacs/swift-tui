import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor @Suite("Button Tests", .snapshots(record: .failed)) struct ButtonTests {
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

        let actionCalled = LockIsolated(false)
        let (application, _) = try drawView(MyView { actionCalled.withValue { $0.toggle() } })

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

        #expect(actionCalled.value == false)
        application.process(key: .init(.enter))
        #expect(actionCalled.value)
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
