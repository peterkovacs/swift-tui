@testable import SwiftTUI
import SnapshotTesting
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

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x3
          → ComposedView<MyView>
            → TupleView<Pack{Text, Divider, Text}>
              → Text:string("Hello") (47, 0) 5x1
              → Divider (0, 1) 100x1
              → Text:string("World") (47, 2) 5x1
        
        """)
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

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 13x100
          → ComposedView<MyView>
            → HStack<TupleView<Pack{Text, Divider, Text}>> (0, 0) 13x100
              → TupleView<Pack{Text, Divider, Text}>
                → Text:string("Hello") (0, 49) 5x1
                → Divider (6, 0) 1x100
                → Text:string("World") (8, 49) 5x1

        """)
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

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 50x50
          → ComposedView<MyView>
            → FixedFrame:50x50 [50x50]
              → SetEnvironmentView<VStack<TupleView<Pack{Text, Divider, Text}>>, DividerStyle>
                → VStack<TupleView<Pack{Text, Divider, Text}>> (0, 23) 50x3
                  → TupleView<Pack{Text, Divider, Text}>
                    → Text:string("Hello") (22, 23) 5x1
                    → Divider (0, 24) 50x1
                    → Text:string("World") (22, 25) 5x1
        
        """)
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

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 50x50
          → ComposedView<MyView>
            → FixedFrame:50x50 [50x50]
              → ZStack<TupleView<Pack{Text, Divider, Text}>> (22, 24) 5x1
                → TupleView<Pack{Text, Divider, Text}>
                  → Text:string("Hello") (22, 24) 5x1
                  → Divider (24, 24) 0x0
                  → Text:string("World") (22, 24) 5x1
        
        """)
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
