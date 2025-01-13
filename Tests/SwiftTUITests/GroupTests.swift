@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor
@Suite("Group Tests") struct GroupTests {
    let record = false

    @Test func testGroupAppliesFrameToChildren() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Group {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 10, height: 3)
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 21x3
          → ComposedView<MyView>
            → HStack<FixedFrame<Group<TupleView<Pack{Text, Text}>>>> (0, 0) 21x3
              → FixedFrame:10x3 [(0, 0) 10x3, (11, 0) 10x3]
                → Group<TupleView<Pack{Text, Text}>>
                  → TupleView<Pack{Text, Text}>
                    → Text:string("Hello") (2, 1) 5x1
                    → Text:string("World") (13, 1) 5x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }
}
