@testable import SwiftTUI
import Testing

@MainActor
@Suite("State Tests") struct StateTests {
    @Test func testUpdatingStateInvalidatesView() async throws {
        struct MyView: View {
            @State var count: Int = 0
            
            var body: some View {
                Text("\(count)")
            }
        }

        let view = MyView()
        let (application, _) = try drawView(view)

        #expect(
            application.node.treeDescription ==
            """
            → VStack<MyView>
              → ComposedView<MyView>
                → Text:string("0") (0, 0) 1x1
            """
        )

        view.count += 1
        #expect(application.invalidated.count == 1)
        #expect(application.invalidated.first === application.node.children[0])

        application.update()
        #expect(
            application.node.treeDescription ==
            """
            → VStack<MyView>
              → ComposedView<MyView>
                → Text:string("1") (0, 0) 1x1
            """
        )

    }
}
