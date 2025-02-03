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
            → ScrollView<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>> [offset:(0, 0) size:7x7] (0, 0) 7x5
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

    @Test func testScrollViewInFrame() async throws {
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
                .frame(height: 5)
                .border()
            }
        }

        // TODO: Why is the X offset by 1?
        let (application, _) = try drawView(MyView())
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x7
          → ComposedView<MyView>
            → Border:[(0, 0) 100x7]
              → FixedFrame:(nil)x5 [98x5]
                → ScrollView<FlexibleFrame<VStack<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>>>> [offset:(0, 0) size:98x10] (1, 1) 98x5
                  → FlexibleFrame:(nil)x(nil)/∞x(nil) [98x10]
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>> (20, 1) 60x10
                      → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                        → Text:string("0123456789 123456789 123456789 123456789 123456789 123456789") (20, 1) 60x1
                        → Text:string("0         10        20        30        40        50") (20, 2) 52x1
                        → Text:string("2 World") (20, 3) 7x1
                        → Text:string("3 Hello") (20, 4) 7x1
                        → Text:string("4 World") (20, 5) 7x1
                        → Text:string("5 Hello") (20, 6) 7x1
                        → Text:string("6 World") (20, 7) 7x1
                        → Text:string("7 World") (20, 8) 7x1
                        → Text:string("8 World") (20, 9) 7x1
                        → Text:string("9 World") (20, 10) 7x1

        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testScrollViewWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    Text("Hello World")
                    Spacer()
                    Text("Goodbye World")
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 13x2
          → ComposedView<MyView>
            → ScrollView<TupleView<Pack{Text, Spacer, Text}>> [offset:(0, 0) size:13x∞] (0, 0) 13x2
              → TupleView<Pack{Text, Spacer, Text}>
                → Text:string("Hello World") (1, 0) 11x1
                → Spacer (6, 1) 1x0
                → Text:string("Goodbye World") (0, 1) 13x1
        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testHorizontalScrollView() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView([.horizontal]) {
                    Text("1 234567890123456789")
                    Text("2 234567890123456789")
                    Text("3 234567890123456789")
                    Text("4 234567890123456789")
                    Text("5 234567890123456789")
                    Text("6 234567890123456789")
                    Text("7 234567890123456789")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 10, height: 7))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 10x7
          → ComposedView<MyView>
            → ScrollView<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>> [offset:(0, 0) size:20x7] (0, 0) 10x7
              → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                → Text:string("1 234567890123456789") (0, 0) 20x1
                → Text:string("2 234567890123456789") (0, 1) 20x1
                → Text:string("3 234567890123456789") (0, 2) 20x1
                → Text:string("4 234567890123456789") (0, 3) 20x1
                → Text:string("5 234567890123456789") (0, 4) 20x1
                → Text:string("6 234567890123456789") (0, 5) 20x1
                → Text:string("7 234567890123456789") (0, 6) 20x1
        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }
}
