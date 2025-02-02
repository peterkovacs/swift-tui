@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor
@Suite("Padding Tests", .snapshots(record: .missing)) struct PaddingTests {
    let record = false
    @Test func testPaddingAroundHStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .padding(.all, 2)
                .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x7
          → ComposedView<MyView>
            → Border:[(0, 0) 25x7]
              → Padding:[(1, 1) 23x5]
                → HStack<TupleView<Pack{Text, Spacer, Text}>> (3, 3) 19x1
                  → TupleView<Pack{Text, Spacer, Text}>
                    → Text:string("Hello") (3, 3) 5x1
                    → Spacer (9, 3) 7x1
                    → Text:string("World") (17, 3) 5x1
        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test(arguments: [
        Edges.top,
        Edges.bottom,
        Edges.left,
        Edges.right,
        [.top, .right],
        [.top, .left],
        [.top, .right, .bottom],
        [.top, .left, .bottom],
        [.bottom, .right],
        [.bottom, .left],
        [.left, .bottom, .right],
        Edges.vertical,
        Edges.horizontal,
        Edges.all,
    ])
    func testPaddingEdges(edges: Edges) async throws {
        struct MyView: View {
            let edges: Edges
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .padding(edges, 1)
                .border()
            }
        }

        let (application, _) = try drawView(MyView(edges: edges), size: .init(width: 25, height: 20))
        assertSnapshot(
            of: application.renderer,
            as: .rendered,
            named: "testPaddingEdges-\(edges.rawValue)"
        )
    }

    @Test func testMultipleBorders() async throws {
        struct MyView: View {
            var body: some View {
                VStack {
                    HStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }
                    .padding()
                    .border()

                    Spacer()

                    HStack {
                        Text("Goodbye")
                        Spacer()
                        Text("World")
                    }
                    .padding(.all, 2)
                    .border()
                }
                .padding()
                .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x20
          → ComposedView<MyView>
            → Border:[(0, 0) 25x20]
              → Padding:[(1, 1) 23x18]
                → VStack<TupleView<Pack{Border<Padding<HStack<TupleView<Pack{Text, Spacer, Text}>>>>, Spacer, Border<Padding<HStack<TupleView<Pack{Text, Spacer, Text}>>>>}>> (2, 2) 21x16
                  → TupleView<Pack{Border<Padding<HStack<TupleView<Pack{Text, Spacer, Text}>>>>, Spacer, Border<Padding<HStack<TupleView<Pack{Text, Spacer, Text}>>>>}>
                    → Border:[(2, 2) 21x5]
                      → Padding:[(3, 3) 19x3]
                        → HStack<TupleView<Pack{Text, Spacer, Text}>> (4, 4) 17x1
                          → TupleView<Pack{Text, Spacer, Text}>
                            → Text:string("Hello") (4, 4) 5x1
                            → Spacer (10, 4) 5x1
                            → Text:string("World") (16, 4) 5x1
                    → Spacer (2, 7) 21x4
                    → Border:[(2, 11) 21x7]
                      → Padding:[(3, 12) 19x5]
                        → HStack<TupleView<Pack{Text, Spacer, Text}>> (5, 14) 15x1
                          → TupleView<Pack{Text, Spacer, Text}>
                            → Text:string("Goodbye") (5, 14) 7x1
                            → Spacer (13, 14) 1x1
                            → Text:string("World") (15, 14) 5x1

        """)
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )    }

    @Test func testBackgroundBehindBorder() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .background(.blue)
                .padding()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x3
          → ComposedView<MyView>
            → Padding:[(0, 0) 25x3]
              → Background<HStack<TupleView<Pack{Text, Spacer, Text}>>>
                → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                  → TupleView<Pack{Text, Spacer, Text}>
                    → Text:string("Hello") (1, 1) 5x1
                    → Spacer (7, 1) 11x1
                    → Text:string("World") (19, 1) 5x1
        
        """)
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

        let bluePixels = application.renderer.window.indices.filter {
            application.renderer.window[$0]?.backgroundColor == .blue
        }

        #expect(Array(Rect(minColumn: 1, minLine: 1, maxColumn: 23, maxLine: 1).indices) == bluePixels)
    }

    @Test func testPaddingBehindBackground() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .padding()
                .background(.blue)
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x3
          → ComposedView<MyView>
            → Background<Padding<HStack<TupleView<Pack{Text, Spacer, Text}>>>>
              → Padding:[(0, 0) 25x3]
                → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                  → TupleView<Pack{Text, Spacer, Text}>
                    → Text:string("Hello") (1, 1) 5x1
                    → Spacer (7, 1) 11x1
                    → Text:string("World") (19, 1) 5x1

        """)
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

        let bluePixels = application.renderer.window.indices.filter {
            application.renderer.window[$0]?.backgroundColor == .blue
        }

        #expect(Array(Rect(minColumn: 0, minLine: 0, maxColumn: 24, maxLine: 2).indices) == bluePixels)

    }

    @Test func testPaddingInPadding() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                    .padding()
                    .border()
                    .padding()
                    .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 13x9
          → ComposedView<MyView>
            → Border:[(0, 0) 13x9]
              → Padding:[(1, 1) 11x7]
                → Border:[(2, 2) 9x5]
                  → Padding:[(3, 3) 7x3]
                    → Text:string("Hello") (4, 4) 5x1
        
        """)

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }
}
