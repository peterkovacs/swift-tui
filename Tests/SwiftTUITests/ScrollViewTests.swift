import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("ScrollView Tests", .snapshots(record: .missing)) struct ScrollViewTests {
    @Test func testRendersContent() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    Text("1 Hello")
                    Text("2 World")
                    Text("3 Hello")
                    Text("4 World")
                    Text("5 Hello")
                    Text("6 World")
                    Text("7 Hello")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 10, height: 5))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 7x5
          → ComposedView<MyView>
            → ScrollView<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>> [(0, 0) 7x7 (0, 0) 7x5
              → VStack<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>> (0, 0) 7x7
                → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                  → Text:string("1 Hello") (0, 0) 7x1
                  → Text:string("2 World") (0, 1) 7x1
                  → Text:string("3 Hello") (0, 2) 7x1
                  → Text:string("4 World") (0, 3) 7x1
                  → Text:string("5 Hello") (0, 4) 7x1
                  → Text:string("6 World") (0, 5) 7x1
                  → Text:string("7 Hello") (0, 6) 7x1
        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test(.disabled()) func testScrollViewInFrame() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("0123456789 123456789 123456789 123456789 123456789 123456789")
                        Text("0         10        20        30        40        50")
                        Text("2 World")
                        Text("3 Hello")
                        Text("4 World")
                        Text("5 Hello")
                        Text("6 World")
                        Text("7 World")
                        Text("8 World")
                        Text("9 World")
                    }
                    .frame(maxWidth: .infinity)
                }
//                .frame(width: 20, height: 5)
                .border()
            }
        }

        // TODO: Why is the X offset by 1?
        let (application, _) = try drawView(MyView())
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 10x5
          → ComposedView<MyView>
            → FixedFrame:10x5 [(0, 0) 10x5]
              → ScrollView<TupleView<Pack{Text, Text, Text, Text, Text, Text}>> offset:(0, 0) (1, 0) 7x5
                → VStack<TupleView<Pack{Text, Text, Text, Text, Text, Text}>> (1, 0) 7x6
                  → TupleView<Pack{Text, Text, Text, Text, Text, Text}>
                    → Text:string("1 Hello") (1, 0) 7x1
                    → Text:string("2 World") (1, 1) 7x1
                    → Text:string("3 Hello") (1, 2) 7x1
                    → Text:string("4 World") (1, 3) 7x1
                    → Text:string("5 Hello") (1, 4) 7x1
                    → Text:string("6 World") (1, 5) 7x1        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
