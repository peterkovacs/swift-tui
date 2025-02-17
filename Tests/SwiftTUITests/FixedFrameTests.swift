import InlineSnapshotTesting
import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Fixed Frame Tests", .snapshots(record: .missing)) struct FixedFrameTest {
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

    @Test func testFrameWidthSpecified() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(width: 50, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 52x3
              → ComposedView<MyView>
                → Border:[(0, 0) 52x3]
                  → FixedFrame:50x(nil) [50x1]
                    → Text:string("Hello World") (20, 1) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }

    @Test func testFrameHeightSpecified() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(height: 30, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 13x32
              → ComposedView<MyView>
                → Border:[(0, 0) 13x32]
                  → FixedFrame:(nil)x30 [11x30]
                    → Text:string("Hello World") (1, 15) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }

    @Test func testFrameLargerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(width: 50, height: 30, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 52x32
              → ComposedView<MyView>
                → Border:[(0, 0) 52x32]
                  → FixedFrame:50x30 [50x30]
                    → Text:string("Hello World") (20, 15) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testFrameSmallerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("HelloWorld")
                    .frame(width: 5, height: 1, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 7x3
              → ComposedView<MyView>
                → Border:[(0, 0) 7x3]
                  → FixedFrame:5x1 [5x1]
                    → Text:string("HelloWorld") (-1, 1) 10x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
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

    @Test func testFramedVStackInHStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    VStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)

                    VStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)

                    VStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)
                }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 62x5
              → ComposedView<MyView>
                → HStack<TupleView<Pack{FixedFrame<VStack<TupleView<Pack{Text, Text}>>>, FixedFrame<VStack<TupleView<Pack{Text, Text}>>>, FixedFrame<VStack<TupleView<Pack{Text, Text}>>>}>> (0, 0) 62x5
                  → TupleView<Pack{FixedFrame<VStack<TupleView<Pack{Text, Text}>>>, FixedFrame<VStack<TupleView<Pack{Text, Text}>>>, FixedFrame<VStack<TupleView<Pack{Text, Text}>>>}>
                    → FixedFrame:20x5 [20x5]
                      → VStack<TupleView<Pack{Text, Text}>> (7, 1) 5x2
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (7, 1) 5x1
                          → Text:string("World") (7, 2) 5x1
                    → FixedFrame:20x5 [20x5]
                      → VStack<TupleView<Pack{Text, Text}>> (28, 1) 5x2
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (28, 1) 5x1
                          → Text:string("World") (28, 2) 5x1
                    → FixedFrame:20x5 [20x5]
                      → VStack<TupleView<Pack{Text, Text}>> (49, 1) 5x2
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (49, 1) 5x1
                          → Text:string("World") (49, 2) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testFramedHStackInVStack() async throws {
        struct MyView: View {
            var body: some View {
                VStack {
                    HStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)

                    HStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)

                    HStack {
                        Text("Hello")
                        Text("World")
                    }
                    .frame(width: 20, height: 5)
                }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 20x15
              → ComposedView<MyView>
                → VStack<TupleView<Pack{FixedFrame<HStack<TupleView<Pack{Text, Text}>>>, FixedFrame<HStack<TupleView<Pack{Text, Text}>>>, FixedFrame<HStack<TupleView<Pack{Text, Text}>>>}>> (0, 0) 20x15
                  → TupleView<Pack{FixedFrame<HStack<TupleView<Pack{Text, Text}>>>, FixedFrame<HStack<TupleView<Pack{Text, Text}>>>, FixedFrame<HStack<TupleView<Pack{Text, Text}>>>}>
                    → FixedFrame:20x5 [20x5]
                      → HStack<TupleView<Pack{Text, Text}>> (4, 2) 11x1
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (4, 2) 5x1
                          → Text:string("World") (10, 2) 5x1
                    → FixedFrame:20x5 [20x5]
                      → HStack<TupleView<Pack{Text, Text}>> (4, 7) 11x1
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (4, 7) 5x1
                          → Text:string("World") (10, 7) 5x1
                    → FixedFrame:20x5 [20x5]
                      → HStack<TupleView<Pack{Text, Text}>> (4, 12) 11x1
                        → TupleView<Pack{Text, Text}>
                          → Text:string("Hello") (4, 12) 5x1
                          → Text:string("World") (10, 12) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
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
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 57x14
              → ComposedView<MyView>
                → Border:[(0, 0) 57x14]
                  → HStack<TupleView<Pack{Border<FixedFrame<Text>>, Border<FixedFrame<Text>>}>> (1, 1) 55x12
                    → TupleView<Pack{Border<FixedFrame<Text>>, Border<FixedFrame<Text>>}>
                      → Border:[(1, 3) 32x7]
                        → FixedFrame:30x5 [30x5]
                          → Text:string("Hello World") (11, 6) 11x1
                      → Border:[(34, 1) 22x12]
                        → FixedFrame:20x10 [20x10]
                          → Text:string("Goodbye World") (38, 6) 13x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Observable
    class Model {
        var size: Size = .init(width: 50, height: 50)

        func update() {
            size = .init(width: size.width / 2, height: size.height  / 2)
        }
    }

    @Test func testObservationInvalidatesLayout() async throws {
        struct MyView: View {
            @State var model: Model

            var body: some View {
                Text("Hello World")
                    .frame(width: model.size.width, height: model.size.height)
            }
        }

        let model = Model()
        let (application, _) = try drawView(MyView(model: model))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x50
              → ComposedView<MyView>
                → FixedFrame:50x50 [50x50]
                  → Text:string("Hello World") (19, 24) 11x1

            """
        }

        model.update()
        #expect(!application.invalidated.isEmpty && application.invalidated.first?.node === application.node.children[0])

        application.update()

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x25
              → ComposedView<MyView>
                → FixedFrame:25x25 [25x25]
                  → Text:string("Hello World") (7, 12) 11x1

            """
        }
    }

    @Test func testInfiniteWidthIsClamped() async throws {
        struct MyView: View {
            var body: some View {
                Group {
                    Text("Hello World")
                    Text("So long and thanks for all the fish")
                        .frame(width: 18, height: 3)
                    Text("Goodbye World")
                }
                .frame(width: .infinity)
                .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 20x11
              → ComposedView<MyView>
                → Border:[(3, 0) 13x3, (0, 3) 20x5, (2, 8) 15x3]
                  → FixedFrame:∞x(nil) [11x1, 18x3, 13x1]
                    → Group<TupleView<Pack{Text, FixedFrame<Text>, Text}>>
                      → TupleView<Pack{Text, FixedFrame<Text>, Text}>
                        → Text:string("Hello World") (4, 1) 11x1
                        → FixedFrame:18x3 [18x3]
                          → Text:string("So long and thanks for all the fish") (1, 4) 18x2
                        → Text:string("Goodbye World") (3, 9) 13x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
