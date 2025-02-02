@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor
@Suite("Group Tests", .snapshots(record: .missing)) struct GroupTests {

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
              → FixedFrame:10x3 [10x3, 10x3]
                → Group<TupleView<Pack{Text, Text}>>
                  → TupleView<Pack{Text, Text}>
                    → Text:string("Hello") (2, 1) 5x1
                    → Text:string("World") (13, 1) 5x1

        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testGroupAppliesBackgroundToChildren() async throws {
        struct MyView: View {
            var body: some View {
                HStack(spacing: 4) {
                    Group {
                        Text("Hello")
                            .frame(width: 5, height: 5)
                        Text("World")
                            .frame(width: 5, height: 5)
                    }
                    .background(.blue)
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 14x5
          → ComposedView<MyView>
            → HStack<Background<Group<TupleView<Pack{FixedFrame<Text>, FixedFrame<Text>}>>>> (0, 0) 14x5
              → Background<Group<TupleView<Pack{FixedFrame<Text>, FixedFrame<Text>}>>>
                → Group<TupleView<Pack{FixedFrame<Text>, FixedFrame<Text>}>>
                  → TupleView<Pack{FixedFrame<Text>, FixedFrame<Text>}>
                    → FixedFrame:5x5 [5x5]
                      → Text:string("Hello") (0, 2) 5x1
                    → FixedFrame:5x5 [5x5]
                      → Text:string("World") (9, 2) 5x1

        """)

        assertSnapshot(
            of: application.renderer,
            as: .background
        )
    }
}
