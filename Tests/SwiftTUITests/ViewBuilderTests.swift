import Testing
@testable import SwiftTUI

@MainActor
@Suite("View Builder Tests") struct ViewBuilderTests {

    @Test func buildEmpty() async throws {
        struct MyView: View {
            var body: some View {
                let _ = ()
            }
        }
        let (application, _) = try drawView(MyView())
        #expect(application.node.treeDescription == """
        → VStack<MyView>
          → ComposedView<MyView>
            → EmptyView
        """)
    }

    @Test func buildIf() async throws {
        struct MyView: View {
            let condition: Bool
            var body: some View {
                if condition {
                    Text("Hello World")
                }
            }
        }

        do {
            let (application, _) = try drawView(MyView(condition: true))
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → OptionalView<Text>
                      → Text:string("Hello World") (0, 0) 11x1
                """)
        }

        do {
            let (application, _) = try drawView(MyView(condition: false))
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → OptionalView<Text>
                """)
        }
    }

    @Test func buildConditional() async throws {
        struct MyView: View {
            let condition: Bool

            var body: some View {
                if condition {
                    Text("Hello World")
                } else {
                    Text("Goodbye World")
                }
            }
        }

        do {
            let (application, _) = try drawView(MyView(condition: true))
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → ConditionalView<Text, Text>
                      → Text:string("Hello World") (0, 0) 11x1
                """)
        }

        do {
            let (application, _) = try drawView(MyView(condition: false))
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → ConditionalView<Text, Text>
                      → Text:string("Goodbye World") (0, 0) 13x1
                """)
        }
    }

    @Test func buildBlock() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → Text:string("Hello World") (0, 0) 11x1
                """)
        }
    }

    @Test func buildTuple2() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                """)
        }
    }

    @Test func buildTuple3() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                """)
        }
    }

    @Test func buildTuple4() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                """)
        }
    }

    @Test func buildTuple5() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                """)
        }
    }

    @Test func buildTuple6() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                """)
        }
    }

    @Test func buildTuple7() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                """)
        }
    }

    @Test func buildTuple8() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                """)
        }
    }

    @Test func buildTuple9() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                      → Text:string("Hello World") (0, 8) 11x1
                """)
        }
    }

    @Test func buildTuple10() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                      → Text:string("Hello World") (0, 8) 11x1
                      → Text:string("Hello World") (0, 9) 11x1
                """)
        }
    }

    @Test func buildTuple11() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                      → Text:string("Hello World") (0, 8) 11x1
                      → Text:string("Hello World") (0, 9) 11x1
                      → Text:string("Hello World") (0, 10) 11x1
                """)
        }
    }

    @Test func buildTuple12() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                      → Text:string("Hello World") (0, 8) 11x1
                      → Text:string("Hello World") (0, 9) 11x1
                      → Text:string("Hello World") (0, 10) 11x1
                      → Text:string("Hello World") (0, 11) 11x1
                """)
        }
    }

    @Test func buildTuple24() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
        }

        do {
            let (application, _) = try drawView(MyView())
            #expect(application.node.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text:string("Hello World") (0, 0) 11x1
                      → Text:string("Hello World") (0, 1) 11x1
                      → Text:string("Hello World") (0, 2) 11x1
                      → Text:string("Hello World") (0, 3) 11x1
                      → Text:string("Hello World") (0, 4) 11x1
                      → Text:string("Hello World") (0, 5) 11x1
                      → Text:string("Hello World") (0, 6) 11x1
                      → Text:string("Hello World") (0, 7) 11x1
                      → Text:string("Hello World") (0, 8) 11x1
                      → Text:string("Hello World") (0, 9) 11x1
                      → Text:string("Hello World") (0, 10) 11x1
                      → Text:string("Hello World") (0, 11) 11x1
                      → Text:string("Hello World") (0, 12) 11x1
                      → Text:string("Hello World") (0, 13) 11x1
                      → Text:string("Hello World") (0, 14) 11x1
                      → Text:string("Hello World") (0, 15) 11x1
                      → Text:string("Hello World") (0, 16) 11x1
                      → Text:string("Hello World") (0, 17) 11x1
                      → Text:string("Hello World") (0, 18) 11x1
                      → Text:string("Hello World") (0, 19) 11x1
                      → Text:string("Hello World") (0, 20) 11x1
                      → Text:string("Hello World") (0, 21) 11x1
                      → Text:string("Hello World") (0, 22) 11x1
                      → Text:string("Hello World") (0, 23) 11x1
                """)
        }
    }

    @Test func testExpression() async throws {
        struct MyView: View {
            var body: some View {
                let s = "Hello" + " " + "World"
                Text(s)
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.treeDescription == """
        → VStack<MyView>
          → ComposedView<MyView>
            → Text:string("Hello World") (0, 0) 11x1
        """)
    }

    @Test func testLimitedAvailability() async throws {
        struct MyView: View {
            var body: some View {
                if #available(macOS 10.15, *) {
                    Text("Mac OS 10.15")
                }

                if #unavailable(macOS 10.15) {
                    Text("Unavailable")
                }
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.treeDescription == """
        → VStack<MyView>
          → ComposedView<MyView>
            → TupleView<Pack{OptionalView<Text>, OptionalView<Text>}>
              → OptionalView<Text>
                → Text:string("Mac OS 10.15") (0, 0) 12x1
              → OptionalView<Text>
        """)
    }

    @Test func testForInLoop() async throws {
        struct MyView: View {
            var body: some View {
                for i in 0..<3 {
                    Text("\(i)")
                }
            }
        }
        
        let (application, _) = try drawView(MyView())

        #expect(application.node.treeDescription == """
        → VStack<MyView>
          → ComposedView<MyView>
            → ArrayView<Text>
              → Text:string("0") (0, 0) 1x1
              → Text:string("1") (0, 1) 1x1
              → Text:string("2") (0, 2) 1x1
        """)

    }
}
