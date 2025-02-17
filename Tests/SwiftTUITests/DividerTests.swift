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
            → VStack<MyView> (0, 0) 100x3
              → ComposedView<MyView>
                → TupleView<Pack{Text, Divider, Text}>
                  → Text:string("Hello") (47, 0) 5x1
                  → Divider (0, 1) 100x1
                  → Text:string("World") (47, 2) 5x1

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
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 13x100
              → ComposedView<MyView>
                → HStack<TupleView<Pack{Text, Divider, Text}>> (0, 0) 13x100
                  → TupleView<Pack{Text, Divider, Text}>
                    → Text:string("Hello") (0, 49) 5x1
                    → Divider (6, 0) 1x100
                    → Text:string("World") (8, 49) 5x1

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
                        Divider()
                        Text("World")
                    }
                    Divider()
                    VStack {
                        Text("Hello")
                        Divider()
                        Text("World")
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
                  → Border:[(0, 0) 50x50]
                    → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Divider, VStack<TupleView<Pack{Text, Divider, Text}>>}>> (1, 1) 48x48
                      → TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Divider, VStack<TupleView<Pack{Text, Divider, Text}>>}>
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (1, 23) 23x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (10, 23) 5x1
                            → Divider (1, 24) 23x1
                            → Text:string("World") (10, 25) 5x1
                        → Divider (24, 1) 1x48
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (25, 23) 24x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (34, 23) 5x1
                            → Divider (25, 24) 24x1
                            → Text:string("World") (34, 25) 5x1

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
                    Divider()
                    Text("World")
                }
                .style(style)
                .frame(width: 50, height: 50)
            }
        }

        let (application, _) = try drawView(MyView(style: style))

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "\(index)",
            record: record
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
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (11, 2) 30x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (23, 2) 5x1
                            → Divider (11, 3) 30x1
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
                    → Border:[(5, 1) 32x5]
                      → FlexibleFrame:(nil)x(nil)/30x(nil) [30x3]
                        → VStack<TupleView<Pack{Text, Divider, Text}>> (6, 2) 30x3
                          → TupleView<Pack{Text, Divider, Text}>
                            → Text:string("Hello") (18, 2) 5x1
                            → Divider (6, 3) 30x1
                            → Text:string("World") (18, 4) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )


    }
}
