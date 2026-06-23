import InlineSnapshotTesting
@testable import SwiftTUI
import Observation
import Testing

@MainActor
@Suite("State Tests", .snapshots(record: .missing)) struct StateTests {
    @Test func testEquatableSetDoesNotInvalidateOnSameValue() async throws {
        struct MyView: View {
            @State var count: Int = 0
            var body: some View { Text("\(count)") }
        }

        let view = MyView()
        let (application, _) = try drawView(view)

        let baseline = application.invalidated.count

        // Setting the same Equatable value must NOT enqueue a new invalidation
        view.count = 0
        #expect(application.invalidated.count == baseline)

        // Setting a different value MUST enqueue exactly one new invalidation
        view.count = 1
        #expect(application.invalidated.count == baseline + 1)
    }

    @Observable class Counter { var value = 0 }

    @Test func testObservableObjectMutationInvalidatesView() async throws {
        struct MyView: View {
            @State var counter: Counter
            var body: some View { Text("\(counter.value)") }
        }

        let counter = Counter()
        let (application, _) = try drawView(MyView(counter: counter))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x1
              → ComposedView<MyView>
                → Text:string("0") (0, 0) 1x1

            """
        }

        counter.value = 42
        #expect(application.invalidated.count == 1)

        application.update()
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 2x1
              → ComposedView<MyView>
                → Text:string("42") (0, 0) 2x1

            """
        }
    }

    @Test func testUpdatingStateInvalidatesView() async throws {
        struct MyView: View {
            @State var count: Int = 0
            var body: some View { Text("\(count)") }
        }

        let view = MyView()
        let (application, _) = try drawView(view)

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x1
              → ComposedView<MyView>
                → Text:string("0") (0, 0) 1x1

            """
        }

        view.count += 1
        #expect(application.invalidated.count == 1)
        #expect(application.invalidated.first?.node === application.node.children[0])

        application.update()
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x1
              → ComposedView<MyView>
                → Text:string("1") (0, 0) 1x1

            """
        }
    }
}
