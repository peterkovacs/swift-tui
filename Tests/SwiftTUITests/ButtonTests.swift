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
}
