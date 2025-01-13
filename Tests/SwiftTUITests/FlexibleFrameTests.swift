import Observation
@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor
@Suite("Flexible Frame Tests") struct FlexibleFrameTest {
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

    @Test func testFrameMinLargerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(minWidth: 50, minHeight: 30, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 52x32
          → ComposedView<MyView>
            → Border:[(0, 0) 52x32]
              → FlexibleFrame:50x30/∞x∞ [(1, 1) 50x30]
                → Text:string("Hello World") (20, 15) 11x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Test func testFrameMaxLargerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(maxWidth: 50, maxHeight: 30, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 13x3
          → ComposedView<MyView>
            → Border:[(0, 0) 13x3]
              → FlexibleFrame:-∞x-∞/50x30 [(1, 1) 11x1]
                → Text:string("Hello World") (1, 1) 11x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }


    @Test func testFrameMinSmallerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(minWidth: 5, minHeight: 1, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 13x3
          → ComposedView<MyView>
            → Border:[(0, 0) 13x3]
              → FlexibleFrame:5x1/∞x∞ [(1, 1) 11x1]
                → Text:string("Hello World") (1, 1) 11x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Test func testFrameMaxSmallerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(maxWidth: 5, maxHeight: 1, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 7x3
          → ComposedView<MyView>
            → Border:[(0, 0) 7x3]
              → FlexibleFrame:-∞x-∞/5x1 [(1, 1) 5x1]
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
                    .frame(minWidth: 50, minHeight: 30, alignment: alignment)
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
                    .frame(minWidth: 30, alignment: alignment)
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
                .frame(minWidth: 30, alignment: alignment)
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
                        .frame(minWidth: 10, maxWidth: 30, minHeight: 5)
                        .border()

                    Text("Goodbye World")
                        .frame(minWidth: 20, minHeight: 10, maxHeight: 100)
                        .border()
                }
                .border()
            }
        }
        

        let (application, _) = try drawView(MyView())
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 38x14
          → ComposedView<MyView>
            → Border:[(0, 0) 38x14]
              → HStack<TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>> (1, 1) 36x12
                → TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>
                  → Border:[(1, 1) 13x7]
                    → FlexibleFrame:10x5/30x∞ [(2, 2) 11x5]
                      → Text:string("Hello World") (2, 4) 11x1
                  → Border:[(15, 1) 22x12]
                    → FlexibleFrame:20x10/∞x100 [(16, 2) 20x10]
                      → Text:string("Goodbye World") (19, 6) 13x1

        """)

        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            record: record
        )
    }

    @Observable
    class Model {
        var minSize: Size = .init(width: 50, height: 50)
        var maxSize: Size = .init(width: 100, height: 100)

        func update() {
            minSize = .init(width: minSize.width / 2, height: minSize.height  / 2)
            maxSize = .init(width: maxSize.width / 2, height: maxSize.height / 2)
        }
    }

    @Test func testObservationInvalidatesLayout() async throws {
        struct MyView: View {
            @State var model: Model

            var body: some View {
                Text("Hello World")
                    .frame(
                        minWidth: model.minSize.width,
                        maxWidth: model.maxSize.width,
                        minHeight: model.minSize.height,
                        maxHeight: model.maxSize.height
                    )
            }
        }

        let model = Model()
        let (application, _) = try drawView(MyView(model: model))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 50x50
          → ComposedView<MyView>
            → FlexibleFrame:50x50/100x100 [(0, 0) 50x50]
              → Text:string("Hello World") (19, 24) 11x1

        """)

        model.update()
        #expect(application.invalidated[0] === application.node.children[0])

        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 50x50
          → ComposedView<MyView>
            → FlexibleFrame:25x25/50x50 [(12, 12) 25x25]
              → Text:string("Hello World") (19, 24) 11x1

        """)
    }
}
