@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor
@Suite("Fixed Frame Tests") struct FixedFrameTest {
    let record = false
    nonisolated static let allAlignments = [
        Alignment.top,
        .bottom,
        .center,
        .leading,
        .trailing,
        .topLeading,
        .topTrailing,
        .bottomLeading,
        .bottomTrailing
    ]

    @Test func testFrameLargerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(width: 50, height: 30, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 52x32
          → ComposedView<MyView>
            → Border:[(0, 0) 52x32]
              → FixedFrame:50x30 [(1, 1) 50x30]
                → Text:string("Hello World") (20, 15) 11x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Test func testFrameSmallerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(width: 5, height: 1, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 7x3
          → ComposedView<MyView>
            → Border:[(0, 0) 7x3]
              → FixedFrame:5x1 [(1, 1) 5x1]
                → Text:string("Hello World") (-2, 1) 11x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Test(arguments: allAlignments) func testFrameAlignment(_ alignment: Alignment) async throws {
        struct MyView: View {
            let alignment: Alignment
            var body: some View {
                Text("Hello World")
                    .frame(width: 50, height: 30, alignment: alignment)
                    .border()
            }
        }
        
        let (application, _) = try drawView(MyView(alignment: alignment))
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "\(alignment.horizontalAlignment)-\(alignment.verticalAlignment)",
            record: record
        )
    }

    @Test(arguments: allAlignments) func testClampWidth(_ alignment: Alignment) async throws {
        struct MyView: View {
            let alignment: Alignment
            var body: some View {
                Text("Hello World")
                    .frame(height: 30, alignment: alignment)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView(alignment: alignment))
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "\(alignment.horizontalAlignment)-\(alignment.verticalAlignment)",
            record: record
        )
    }

    @Test(arguments: allAlignments) func testClampHeight(_ alignment: Alignment) async throws {
        struct MyView: View {
            let alignment: Alignment
            var body: some View {
                VStack {
                    Text("Hello World")
                    Text("Hello World")
                    Text("Hello World")
                }
                .frame(width: 30, alignment: alignment)
                .border()
            }
        }

        let (application, _) = try drawView(MyView(alignment: alignment))
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "\(alignment.horizontalAlignment)-\(alignment.verticalAlignment)",
            record: record
        )
    }

    @Test func textComplexView() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .center, spacing: 1) {
                    Text("Hello World")
                    .frame(width: 30, height: 5)
                    .border()

                    Text("Goodbye World")
                    .frame(width: 20, height: 10)
                    .border()
                }
                .border()
            }
        }
        

        let (application, _) = try drawView(MyView())
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 57x14
          → ComposedView<MyView>
            → Border:[(0, 0) 57x14]
              → HStack<TupleView<Pack{Border<FixedFrame<Text>>, Border<FixedFrame<Text>>}>> (1, 1) 55x12
                → TupleView<Pack{Border<FixedFrame<Text>>, Border<FixedFrame<Text>>}>
                  → Border:[(1, 1) 32x7]
                    → FixedFrame:30x5 [(2, 2) 30x5]
                      → Text:string("Hello World") (11, 4) 11x1
                  → Border:[(34, 1) 22x12]
                    → FixedFrame:20x10 [(35, 2) 20x10]
                      → Text:string("Goodbye World") (38, 6) 13x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }
}
