import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Divider Tests", .snapshots(record: .missing, diffTool: .ksdiff)) struct DividerTests {
    let record = false

    @Test func testHorizontalDivider() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                Divider()
                Text("World")
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x3
              → ComposedView<MyView>
                → TupleView<Pack{Text, Divider, Text}>
                  → Text:string("Hello") (0, 0) 5x1
                  → Divider (0, 1) 5x1
                  → Text:string("World") (0, 2) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testVerticalDivider() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Divider()
                    Text("World")
                }
                .frame(width: 20)
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 20x1
              → ComposedView<MyView>
                → FixedFrame:20x(nil) [20x1]
                  → HStack<TupleView<Pack{Text, Divider, Text}>> (3, 0) 13x1
                    → TupleView<Pack{Text, Divider, Text}>
                      → Text:string("Hello") (3, 0) 5x1
                      → Divider (9, 0) 1x1
                      → Text:string("World") (11, 0) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testComplexDivider() async throws {
        struct MyView: View {
            var body: some View {
                HStack(spacing: 0) {
                    VStack {
                        Text("Hello")
                            .frame(width: 20)
                        Divider()
                        Text("World")
                            .frame(height: 20)
                    }
                    Divider()
                    VStack {
                        Text("Hello")
                            .frame(height: 20)
                        Divider()
                        Text("World")
                            .frame(width: 20)
                    }
                }
                .border()
                .frame(width: 50, height: 50)
            }
        }

        let (application, _) = try drawView(MyView())
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x50
              → ComposedView<MyView>
                → FixedFrame:50x50 [50x50]
                  → Border:[(3, 13) 43x24]
                    → HStack<TupleView<Pack{VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>>, Divider, VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>>}>> (4, 14) 41x22
                      → TupleView<Pack{VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>>, Divider, VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>>}>
                        → VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>> (4, 14) 20x22
                          → TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>
                            → FixedFrame:20x(nil) [20x1]
                              → Text:string("Hello") (11, 14) 5x1
                            → Divider (4, 15) 20x1
                            → FixedFrame:(nil)x20 [5x20]
                              → Text:string("World") (11, 25) 5x1
                        → Divider (24, 14) 1x22
                        → VStack<TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>> (25, 14) 20x22
                          → TupleView<Pack{FixedFrame<Text>, Divider, FixedFrame<Text>}>
                            → FixedFrame:(nil)x20 [5x20]
                              → Text:string("Hello") (32, 23) 5x1
                            → Divider (25, 34) 20x1
                            → FixedFrame:20x(nil) [20x1]
                              → Text:string("World") (32, 35) 5x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    nonisolated static let allStyles = [
        DividerStyle.default,
        .double,
        .heavy
    ]

    @Test(arguments: zip(allStyles.indices, allStyles)) func testDividerStyle(index: Int, style: DividerStyle) async throws {
        struct MyView: View {
            let style: DividerStyle

            var body: some View {
                VStack {
                    Text("Hello")
                        .frame(width: 50)
                    Divider()
                    Text("World")
                }
                .frame(width: 50, height: 50)
                .style(style)
            }
        }

        let (application, _) = try drawView(MyView(style: style))

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "\(index)"
        )
    }

    @Test func testDividerInZStack() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    Text("Hello")
                    Divider()
                    Text("World")
                }
                .frame(width: 50, height: 50)
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x50
              → ComposedView<MyView>
                → FixedFrame:50x50 [50x50]
                  → ZStack<TupleView<Pack{Text, Divider, Text}>> (22, 24) 5x1
                    → TupleView<Pack{Text, Divider, Text}>
                      → Text:string("Hello") (22, 24) 5x1
                      → Divider (24, 24) 0x0
                      → Text:string("World") (22, 24) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }

    @Test func testDividerInFrame() async throws {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Divider()
                    Text("World")
                }
                .frame(width: 30)
                .border()
                .frame(width: 50)
                .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 52x7
              → ComposedView<MyView>
                → Border:[(0, 0) 52x7]
                  → FixedFrame:50x(nil) [50x5]
                    → Border:[(10, 1) 32x5]
                      → FixedFrame:30x(nil) [30x3]
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (23, 2) 5x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (23, 2) 5x1
                            → Divider (23, 3) 5x1
                            → Text:string("World") (23, 4) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testDividerInFlexibleFrame() async throws {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Divider()
                    Text("World")
                }
                .frame(maxWidth: 30)
                .border()
                .frame(minWidth: 40, maxWidth: 50)
                .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 42x7
              → ComposedView<MyView>
                → Border:[(0, 0) 42x7]
                  → FlexibleFrame:40x(nil)/50x(nil) [40x5]
                    → Border:[(17, 1) 7x5]
                      → FlexibleFrame:(nil)x(nil)/30x(nil) [5x3]
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (18, 2) 5x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (18, 2) 5x1
                            → Divider (18, 3) 5x1
                            → Text:string("World") (18, 4) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )


    }
}
