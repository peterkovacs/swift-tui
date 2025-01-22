import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Geometry Reader Tests") struct GeometryReaderTests {
    let record = false

    @Test func testReadsGeometryDuringLayout() async throws {
        struct MyView: View {
            var body: some View {
                GeometryReader { size in
                    Text("\(size)")
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x100
          → ComposedView<MyView>
            → GeometryReader<Text> (0, 0) 100x100
              → Text:string("0x0") (0, 0) 3x1

        """)

        #expect(!application.invalidated.isEmpty)
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x100
          → ComposedView<MyView>
            → GeometryReader<Text> (0, 0) 100x100
              → Text:string("100x100") (0, 0) 7x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Test func testReadsGeometryWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    GeometryReader { size in
                        Spacer()
                        Text("\(size)")
                        Spacer()
                    }
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x100
          → ComposedView<MyView>
            → HStack<TupleView<Pack{Text, GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>>, Text}>> (0, 0) 100x100
              → TupleView<Pack{Text, GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>>, Text}>
                → Text:string("Hello") (0, 49) 5x1
                → GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>> (6, 0) 88x100
                  → TupleView<Pack{Spacer, Text, Spacer}>
                    → Spacer
                    → Text:string("0x0") (6, 0) 3x1
                    → Spacer
                → Text:string("World") (95, 49) 5x1

        """)

        #expect(!application.invalidated.isEmpty)
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x100
          → ComposedView<MyView>
            → HStack<TupleView<Pack{Text, GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>>, Text}>> (0, 0) 100x100
              → TupleView<Pack{Text, GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>>, Text}>
                → Text:string("Hello") (0, 49) 5x1
                → GeometryReader<TupleView<Pack{Spacer, Text, Spacer}>> (6, 0) 88x100
                  → TupleView<Pack{Spacer, Text, Spacer}>
                    → Spacer
                    → Text:string("88x100") (6, 0) 6x1
                    → Spacer
                → Text:string("World") (95, 49) 5x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )

    }
}
