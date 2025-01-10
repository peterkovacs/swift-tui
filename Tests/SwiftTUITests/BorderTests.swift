@testable import SwiftTUI
import Testing
import SnapshotTesting

@MainActor @Suite("Border Tests") struct BorderTests {
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
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x3
          → ComposedView<MyView>
            → Border:[(0, 0) 25x3]
              → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                → TupleView<Pack{Text, Spacer, Text}>
                  → Text:string("Hello") (1, 1) 5x1
                  → Spacer (7, 1) 11x1
                  → Text:string("World") (19, 1) 5x1
        
        """)
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines
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
        #expect(application.node.frameDescription == """
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
                  → Spacer (1, 4) 23x12
                  → Border:[(1, 16) 23x3]
                    → HStack<TupleView<Pack{Text, Spacer, Text}>> (2, 17) 21x1
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Goodbye") (2, 17) 7x1
                        → Spacer (10, 17) 7x1
                        → Text:string("World") (18, 17) 5x1
        
        """)
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines
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
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x3
          → ComposedView<MyView>
            → Border:[(0, 0) 25x3]
              → Background<HStack<TupleView<Pack{Text, Spacer, Text}>>>
                → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                  → TupleView<Pack{Text, Spacer, Text}>
                    → Text:string("Hello") (1, 1) 5x1
                    → Spacer (7, 1) 11x1
                    → Text:string("World") (19, 1) 5x1
        
        """)
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines
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
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 25x3
          → ComposedView<MyView>
            → Background<Border<HStack<TupleView<Pack{Text, Spacer, Text}>>>>
              → Border:[(0, 0) 25x3]
                → HStack<TupleView<Pack{Text, Spacer, Text}>> (1, 1) 23x1
                  → TupleView<Pack{Text, Spacer, Text}>
                    → Text:string("Hello") (1, 1) 5x1
                    → Spacer (7, 1) 11x1
                    → Text:string("World") (19, 1) 5x1
        
        """)
        assertSnapshot(
            of: (application.renderer as! TestRenderer).description,
            as: .lines
        )

        let bluePixels = application.renderer.window.indices.filter {
            application.renderer.window[$0]?.backgroundColor == .blue
        }

        #expect(Array(Rect(minColumn: 0, minLine: 0, maxColumn: 24, maxLine: 2).indices) == bluePixels)

    }
}
