@testable import SwiftTUI
import Testing
import SnapshotTesting
import InlineSnapshotTesting

@MainActor @Suite("Border Tests", .snapshots(record: .missing, diffTool: .ksdiff)) struct BorderTests {
    let record = false

    @Test func testBorderAroundHStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x3
              → ComposedView<MyView>
                → Border:[(0, 0) 25x3]
                  → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                    → TupleView<Pack{Text, Spacer, Text}>
                      → Text:string("Hello") (1, 1) 5x1
                      → Spacer (7, 1) 11x1
                      → Text:string("World") (19, 1) 5x1

            """
        }

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
    func testBorderEdges(edges: Edges) async throws {
        struct MyView: View {
            let edges: Edges
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .border(edges: edges)
            }
        }

        let (application, _) = try drawView(MyView(edges: edges), size: .init(width: 25, height: 20))
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines,
            named: "testBorderEdges-\(edges.rawValue)"
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
                    .border()

                    Spacer()

                    HStack {
                        Text("Goodbye")
                        Spacer()
                        Text("World")
                    }
                    .border()
                }
                .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x20
              → ComposedView<MyView>
                → Border:[(0, 0) 25x20]
                  → VStack<TupleView<Pack{Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>, Spacer, Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>}>> (1, 1) 23x18
                    → TupleView<Pack{Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>, Spacer, Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>}>
                      → Border:[(1, 1) 23x3]
                        → HStack<TupleView<Pack{Text, Spacer, Text}>> (2, 2) 21x1
                          → TupleView<Pack{Text, Spacer, Text}>
                            → Text:string("Hello") (2, 2) 5x1
                            → Spacer (8, 2) 9x1
                            → Text:string("World") (18, 2) 5x1
                      → Spacer (12, 4) 1x12
                      → Border:[(1, 16) 23x3]
                        → HStack<TupleView<Pack{Text, Spacer, Text}>> (2, 17) 21x1
                          → TupleView<Pack{Text, Spacer, Text}>
                            → Text:string("Goodbye") (2, 17) 7x1
                            → Spacer (10, 17) 7x1
                            → Text:string("World") (18, 17) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testBackgroundBehindBorder() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .background(.blue)
                .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x3
              → ComposedView<MyView>
                → Border:[(0, 0) 25x3]
                  → Background<HStack<TupleView<Pack{Text, Spacer, Text}>>>
                    → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (1, 1) 5x1
                        → Spacer (7, 1) 11x1
                        → Text:string("World") (19, 1) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

        let bluePixels = application.renderer.window.indices.filter {
            application.renderer.window[$0]?.backgroundColor == .blue
        }

        #expect(Array(Rect(minColumn: 1, minLine: 1, maxColumn: 23, maxLine: 1).indices) == bluePixels)
    }

    @Test func testBorderBehindBackground() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
                .border()
                .background(.blue)
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 25, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 25x3
              → ComposedView<MyView>
                → Background<Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>>
                  → Border:[(0, 0) 25x3]
                    → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (1, 1) 5x1
                        → Spacer (7, 1) 11x1
                        → Text:string("World") (19, 1) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

        let bluePixels = application.renderer.window.indices.filter {
            application.renderer.window[$0]?.backgroundColor == .blue
        }

        #expect(Array(Rect(minColumn: 0, minLine: 0, maxColumn: 24, maxLine: 2).indices) == bluePixels)

    }

    @Test func testBorderInBorder() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                    .border()
                    .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 9x5
              → ComposedView<MyView>
                → Border:[(0, 0) 9x5]
                  → Border:[(1, 1) 7x3]
                    → Text:string("Hello") (2, 2) 5x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testBorderInHStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                        .border()
                    Text("World")
                        .border()
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 15x3
              → ComposedView<MyView>
                → HStack<TupleView<Pack{Border<Text>, Border<Text>}>> (0, 0) 15x3
                  → TupleView<Pack{Border<Text>, Border<Text>}>
                    → Border:[(0, 0) 7x3]
                      → Text:string("Hello") (1, 1) 5x1
                    → Border:[(8, 0) 7x3]
                      → Text:string("World") (9, 1) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }

    @Test func testBorderInVStack() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                    .border()
                Text("World")
                    .border()
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 7x6
              → ComposedView<MyView>
                → TupleView<Pack{Border<Text>, Border<Text>}>
                  → Border:[(0, 0) 7x3]
                    → Text:string("Hello") (1, 1) 5x1
                  → Border:[(0, 3) 7x3]
                    → Text:string("World") (1, 4) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }

    @Test func testBorderInZStack() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    Text("Hello        World")
                        .padding()
                        .border()
                    Text("On Top")
                        .border()
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 22x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Border<Padding<Text>>, Border<Text>}>> (0, 0) 22x5
                  → TupleView<Pack{Border<Padding<Text>>, Border<Text>}>
                    → Border:[(0, 0) 22x5]
                      → Padding:[(1, 1) 20x3]
                        → Text:string("Hello        World") (2, 2) 18x1
                    → Border:[(7, 1) 8x3]
                      → Text:string("On Top") (8, 2) 6x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
