import InlineSnapshotTesting
import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("ScrollView Tests", .snapshots(record: .failed)) struct ScrollViewTests {
    @Test func testRendersContent() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    Text("1 Hello")
                    Text("2 World")
                    Text("3 Hello")
                    Text("4 World")
                    Text("5 Hello")
                    Text("6 World")
                    Text("7 Hello")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 10, height: 5))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 7x5
              → ComposedView<MyView>
                → ScrollView [offset:(0, 0) size:7x7] (0, 0) 7x5
                  → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                    → Text:string("1 Hello") (0, 0) 7x1
                    → Text:string("2 World") (0, 1) 7x1
                    → Text:string("3 Hello") (0, 2) 7x1
                    → Text:string("4 World") (0, 3) 7x1
                    → Text:string("5 Hello") (0, 4) 7x1
                    → Text:string("6 World") (0, 5) 7x1
                    → Text:string("7 Hello") (0, 6) 7x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testScrollViewInFrame() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("0123456789 123456789 123456789 123456789 123456789 123456789")
                        Text("0         10        20        30        40        50")
                        Text("2 World")
                        Text("3 Hello")
                        Text("4 World")
                        Text("5 Hello")
                        Text("6 World")
                        Text("7 World")
                        Text("8 World")
                        Text("9 World")
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 5)
                .border()
            }
        }

        let (application, _) = try drawView(MyView())
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 100x7
              → ComposedView<MyView>
                → Border:[(0, 0) 100x7]
                  → FixedFrame:(nil)x5 [98x5]
                    → ScrollView [offset:(0, 0) size:98x10] (1, 1) 98x5
                      → FlexibleFrame:(nil)x(nil)/∞x(nil) [98x10]
                        → VStack<TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>> (19, 0) 60x10
                          → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                            → Text:string("0123456789 123456789 123456789 123456789 123456789 123456789") (19, 0) 60x1
                            → Text:string("0         10        20        30        40        50") (19, 1) 52x1
                            → Text:string("2 World") (19, 2) 7x1
                            → Text:string("3 Hello") (19, 3) 7x1
                            → Text:string("4 World") (19, 4) 7x1
                            → Text:string("5 Hello") (19, 5) 7x1
                            → Text:string("6 World") (19, 6) 7x1
                            → Text:string("7 World") (19, 7) 7x1
                            → Text:string("8 World") (19, 8) 7x1
                            → Text:string("9 World") (19, 9) 7x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testScrollViewWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView {
                    Text("Hello World")
                    Spacer()
                    Text("Goodbye World")
                }
                .border()
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 15x4
              → ComposedView<MyView>
                → Border:[(0, 0) 15x4]
                  → ScrollView [offset:(0, 0) size:13x∞] (1, 1) 13x2
                    → TupleView<Pack{Text, Spacer, Text}>
                      → Text:string("Hello World") (1, 0) 11x1
                      → Spacer (6, 1) 1x0
                      → Text:string("Goodbye World") (0, 1) 13x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testHorizontalScrollView() async throws {
        struct MyView: View {
            var body: some View {
                ScrollView([.horizontal]) {
                    Text("1 234567890123456789")
                    Text("2 234567890123456789")
                    Text("3 234567890123456789")
                    Text("4 234567890123456789")
                    Text("5 234567890123456789")
                    Text("6 234567890123456789")
                    Text("7 234567890123456789")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 10, height: 7))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x7
              → ComposedView<MyView>
                → ScrollView [offset:(0, 0) size:20x7] (0, 0) 10x7
                  → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                    → Text:string("1 234567890123456789") (0, 0) 20x1
                    → Text:string("2 234567890123456789") (0, 1) 20x1
                    → Text:string("3 234567890123456789") (0, 2) 20x1
                    → Text:string("4 234567890123456789") (0, 3) 20x1
                    → Text:string("5 234567890123456789") (0, 4) 20x1
                    → Text:string("6 234567890123456789") (0, 5) 20x1
                    → Text:string("7 234567890123456789") (0, 6) 20x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testBigScrollView() async throws {
        struct MyView: View {
            @State var text1: String = ""
            @State var text2: String = ""
            @State var text3: String = ""
            @State var text4: String = ""
            @State var text5: String = ""
            var body: some View {
                ScrollView {
                    Text("""
                    Lorem ipsum odor amet, consectetuer adipiscing elit. Ipsum himenaeos a aenean id metus. Lacus donec mauris posuere vestibulum leo. Risus convallis ornare bibendum arcu fames penatibus rutrum diam. Mi vehicula est lacus facilisis mi porta? Velit elementum feugiat placerat quisque justo ante ullamcorper porttitor arcu. Montes porttitor habitasse habitasse in augue euismod. Maecenas ultrices amet neque natoque, in aliquet integer.

                    Ligula habitant etiam ornare habitant venenatis. Commodo fermentum eleifend feugiat class tempus. Viverra elementum placerat morbi nec consequat. Metus suspendisse tincidunt mus ornare libero sodales tempus mattis ultricies. Ante laoreet porta, scelerisque finibus ultrices auctor. Vulputate leo laoreet ullamcorper sit est. Fusce eget varius primis; nisi maximus ipsum ullamcorper dictum. Porttitor aptent purus quisque porta urna neque cras netus placerat.

                    Penatibus pharetra sapien ligula eu efficitur quis sem in morbi. Ac pulvinar torquent risus bibendum curae. Ligula bibendum per velit hac sodales nibh; vivamus in aliquet. Curabitur vestibulum curabitur platea tellus finibus felis mi justo. Imperdiet vel facilisis ex habitant vestibulum pulvinar vitae. Neque lacinia interdum himenaeos himenaeos hendrerit bibendum a. Litora pellentesque nibh ac magnis elit eget.

                    Rhoncus odio lacus leo mauris fames quam metus tempus potenti. Luctus eros finibus tincidunt taciti praesent scelerisque mus. Consectetur sem pharetra montes odio risus praesent semper. Adipiscing porta proin aliquam praesent suscipit velit. Posuere commodo pretium viverra, imperdiet diam tortor dis dapibus. Enim mi congue placerat hendrerit ipsum elit cursus. Aliquet luctus erat efficitur pulvinar enim. Diam in hendrerit, pellentesque egestas parturient posuere dapibus amet. Ultricies odio vulputate lacus porttitor integer fames nascetur lobortis porttitor. Montes justo senectus praesent lacus curae sagittis.

                    Himenaeos magna egestas; fringilla fringilla nec sollicitudin augue maecenas? Vestibulum imperdiet blandit rhoncus nibh eu maximus quis rutrum litora? Maecenas ligula nisl aliquet lorem cursus scelerisque eu non lobortis. Lobortis sagittis vivamus facilisi porta velit elementum vehicula vulputate. Accumsan augue hac scelerisque auctor taciti inceptos augue malesuada parturient. Scelerisque sem nisl massa laoreet; odio potenti quis orci venenatis. Quisque enim finibus ligula maecenas vestibulum class quam consequat. Maecenas mauris aenean in fringilla per.
                    """)
                    TextField("Text 1", text: $text1) { _ in }.frame(width: 20).border()
                    TextField("Text 2", text: $text2) { _ in }.frame(width: 20).border()
                    TextField("Text 3", text: $text3) { _ in }.frame(width: 20).border()
                    TextField("Text 4", text: $text4) { _ in }.frame(width: 20).border()
                    TextField("Text 5", text: $text5) { _ in }.frame(width: 20).border()
                }
                .frame(width: 40, height: 30)
                .border()
            }
        }


        let (application, _) = try drawView(MyView(), size: .init(width: 120, height: 50))
        #expect((application.node.focusManager.focusedElement?.node as? Node)?.description  == "ScrollView [offset:(0, 0) size:40x85]")
        assertInlineSnapshot(of: application, as: .frameDescription) {
            #"""
            → VStack<MyView> (0, 0) 42x32
              → ComposedView<MyView>
                → Border:[(0, 0) 42x32]
                  → FixedFrame:40x30 [40x30]
                    → ScrollView [offset:(0, 0) size:40x85] (1, 1) 40x30
                      → TupleView<Pack{Text, Border<FixedFrame<TextField>>, Border<FixedFrame<TextField>>, Border<FixedFrame<TextField>>, Border<FixedFrame<TextField>>, Border<FixedFrame<TextField>>}>
                        → Text:string("Lorem ipsum odor amet, consectetuer adipiscing elit. Ipsum himenaeos a aenean id metus. Lacus donec mauris posuere vestibulum leo. Risus convallis ornare bibendum arcu fames penatibus rutrum diam. Mi vehicula est lacus facilisis mi porta? Velit elementum feugiat placerat quisque justo ante ullamcorper porttitor arcu. Montes porttitor habitasse habitasse in augue euismod. Maecenas ultrices amet neque natoque, in aliquet integer.\n\nLigula habitant etiam ornare habitant venenatis. Commodo fermentum eleifend feugiat class tempus. Viverra elementum placerat morbi nec consequat. Metus suspendisse tincidunt mus ornare libero sodales tempus mattis ultricies. Ante laoreet porta, scelerisque finibus ultrices auctor. Vulputate leo laoreet ullamcorper sit est. Fusce eget varius primis; nisi maximus ipsum ullamcorper dictum. Porttitor aptent purus quisque porta urna neque cras netus placerat.\n\nPenatibus pharetra sapien ligula eu efficitur quis sem in morbi. Ac pulvinar torquent risus bibendum curae. Ligula bibendum per velit hac sodales nibh; vivamus in aliquet. Curabitur vestibulum curabitur platea tellus finibus felis mi justo. Imperdiet vel facilisis ex habitant vestibulum pulvinar vitae. Neque lacinia interdum himenaeos himenaeos hendrerit bibendum a. Litora pellentesque nibh ac magnis elit eget.\n\nRhoncus odio lacus leo mauris fames quam metus tempus potenti. Luctus eros finibus tincidunt taciti praesent scelerisque mus. Consectetur sem pharetra montes odio risus praesent semper. Adipiscing porta proin aliquam praesent suscipit velit. Posuere commodo pretium viverra, imperdiet diam tortor dis dapibus. Enim mi congue placerat hendrerit ipsum elit cursus. Aliquet luctus erat efficitur pulvinar enim. Diam in hendrerit, pellentesque egestas parturient posuere dapibus amet. Ultricies odio vulputate lacus porttitor integer fames nascetur lobortis porttitor. Montes justo senectus praesent lacus curae sagittis.\n\nHimenaeos magna egestas; fringilla fringilla nec sollicitudin augue maecenas? Vestibulum imperdiet blandit rhoncus nibh eu maximus quis rutrum litora? Maecenas ligula nisl aliquet lorem cursus scelerisque eu non lobortis. Lobortis sagittis vivamus facilisi porta velit elementum vehicula vulputate. Accumsan augue hac scelerisque auctor taciti inceptos augue malesuada parturient. Scelerisque sem nisl massa laoreet; odio potenti quis orci venenatis. Quisque enim finibus ligula maecenas vestibulum class quam consequat. Maecenas mauris aenean in fringilla per.") (0, 0) 40x70
                        → Border:[(9, 70) 22x3]
                          → FixedFrame:20x(nil) [20x1]
                            → TextField:"" (0) FOCUSED (10, 71) 20x1
                        → Border:[(9, 73) 22x3]
                          → FixedFrame:20x(nil) [20x1]
                            → TextField:"" (0) (10, 74) 20x1
                        → Border:[(9, 76) 22x3]
                          → FixedFrame:20x(nil) [20x1]
                            → TextField:"" (0) (10, 77) 20x1
                        → Border:[(9, 79) 22x3]
                          → FixedFrame:20x(nil) [20x1]
                            → TextField:"" (0) (10, 80) 20x1
                        → Border:[(9, 82) 22x3]
                          → FixedFrame:20x(nil) [20x1]
                            → TextField:"" (0) (10, 83) 20x1

            """#
        }
        assertSnapshot(of: application.renderer, as: .rendered)

        application.process(key: .init(.down))
        #expect((application.node.children[0].children[0].children[0].children[0] as? ScrollViewNode)?.contentOffset == .init(column: 0, line: 1))

        application.process(keys: "Hello World")
        assertSnapshot(of: application.renderer, as: .rendered)
    }

    @Observable
    class Model {
        var count: Int = 30
    }

    @Test func contentsExpandsWithPositiveContentOffset() async throws {
        struct MyView: View {
            @State var model: Model

            var body: some View {
                ScrollView {
                    ForEach(0..<model.count, id: \.self) { index in
                        Text("\(index)")
                    }
                }
                .frame(height: 20)
            }
        }

        let model = Model()
        let (application, _) = try drawView(MyView(model: model))

        application.process(key: .init(.pageDown))
        #expect((application.node.children[0].children[0].children[0] as? ScrollViewNode)?.contentOffset == .init(column: 0, line: 10))

        model.count += 30
        application.update()

        #expect((application.node.children[0].children[0].children[0] as? ScrollViewNode)?.contentOffset == .init(column: 0, line: 10))

        assertSnapshot(
            of: application.renderer,
            as: .rendered 
        )
    }

    @Test func contextContractsWithPositiveContentOffset() async throws {
        struct MyView: View {
            @State var model: Model

            var body: some View {
                ScrollView {
                    ForEach(0..<model.count, id: \.self) { index in
                        Text("\(index)")
                    }
                }
                .frame(width: 10, height: 20)
            }
        }

        let model = Model()
        model.count = 60
        let (application, _) = try drawView(MyView(model: model))

        application.process(key: .init(.pageDown))
        #expect((application.node.children[0].children[0].children[0] as? ScrollViewNode)?.contentOffset == .init(column: 0, line: 20))

        model.count -= 30
        application.update()

        #expect((application.node.children[0].children[0].children[0] as? ScrollViewNode)?.contentOffset == .init(column: 0, line: 10))

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
