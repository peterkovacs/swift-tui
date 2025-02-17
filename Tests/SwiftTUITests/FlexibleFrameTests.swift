import InlineSnapshotTesting
import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Flexible Frame Tests", .snapshots(record: .missing)) struct FlexibleFrameTest {
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

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 52x32
              → ComposedView<MyView>
                → Border:[(0, 0) 52x32]
                  → FlexibleFrame:50x30/(nil)x(nil) [50x30]
                    → Text:string("Hello World") (20, 15) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
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

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 13x3
              → ComposedView<MyView>
                → Border:[(0, 0) 13x3]
                  → FlexibleFrame:(nil)x(nil)/50x30 [11x1]
                    → Text:string("Hello World") (1, 1) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
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

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 13x3
              → ComposedView<MyView>
                → Border:[(0, 0) 13x3]
                  → FlexibleFrame:5x1/(nil)x(nil) [11x1]
                    → Text:string("Hello World") (1, 1) 11x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testFrameMaxSmallerThanText() async throws {
        struct MyView: View {
            var body: some View {
                Text("HelloWorld")
                    .frame(maxWidth: 5, maxHeight: 1, alignment: .center)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 7x3
              → ComposedView<MyView>
                → Border:[(0, 0) 7x3]
                  → FlexibleFrame:(nil)x(nil)/5x1 [5x1]
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

    @Test(arguments: allAlignments) func testInfiniteFrameAlignment(_ alignment: Alignment) async throws {
        struct MyView: View {
            let alignment: Alignment
            var body: some View {
                Text("Hello World")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
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
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 38x14
              → ComposedView<MyView>
                → Border:[(0, 0) 38x14]
                  → HStack<TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>> (1, 1) 36x12
                    → TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>
                      → Border:[(1, 3) 13x7]
                        → FlexibleFrame:10x5/30x(nil) [11x5]
                          → Text:string("Hello World") (2, 6) 11x1
                      → Border:[(15, 1) 22x12]
                        → FlexibleFrame:20x10/(nil)x100 [20x10]
                          → Text:string("Goodbye World") (19, 6) 13x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
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

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x50
              → ComposedView<MyView>
                → FlexibleFrame:50x50/100x100 [50x50]
                  → Text:string("Hello World") (19, 24) 11x1

            """
        }
        model.update()
        #expect(application.invalidated.first?.node === application.node.children[0])

        application.update()

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x25
              → ComposedView<MyView>
                → FlexibleFrame:25x25/50x50 [25x25]
                  → Text:string("Hello World") (7, 12) 11x1

            """
        }
    }

    @Test func testInfinitelyWideFrameUsesFullWidth() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                        .frame(maxWidth: .infinity)
                        .border()
                    Text("World")
                        .frame(maxWidth: .infinity)
                        .border()
                }
            }
        }
        
        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x3
              → ComposedView<MyView>
                → HStack<TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>> (0, 0) 100x3
                  → TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>
                    → Border:[(0, 0) 50x3]
                      → FlexibleFrame:(nil)x(nil)/∞x(nil) [48x1]
                        → Text:string("Hello") (22, 1) 5x1
                    → Border:[(51, 0) 49x3]
                      → FlexibleFrame:(nil)x(nil)/∞x(nil) [47x1]
                        → Text:string("World") (73, 1) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testInfinitelyHighFrameUsesFullHeight() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(maxHeight: .infinity)
                    .border()
                Text("Goodbye World")
                    .frame(maxHeight: .infinity)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 15x100
              → ComposedView<MyView>
                → TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>
                  → Border:[(1, 0) 13x50]
                    → FlexibleFrame:(nil)x(nil)/(nil)x∞ [11x48]
                      → Text:string("Hello World") (2, 24) 11x1
                  → Border:[(0, 50) 15x50]
                    → FlexibleFrame:(nil)x(nil)/(nil)x∞ [13x48]
                      → Text:string("Goodbye World") (1, 74) 13x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testInfinitelyLargeFrameUsesFullSize() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .border()
                Text("Goodbye World")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x100
              → ComposedView<MyView>
                → TupleView<Pack{Border<FlexibleFrame<Text>>, Border<FlexibleFrame<Text>>}>
                  → Border:[(0, 0) 100x50]
                    → FlexibleFrame:(nil)x(nil)/∞x∞ [98x48]
                      → Text:string("Hello World") (44, 24) 11x1
                  → Border:[(0, 50) 100x50]
                    → FlexibleFrame:(nil)x(nil)/∞x∞ [98x48]
                      → Text:string("Goodbye World") (43, 74) 13x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }
}
