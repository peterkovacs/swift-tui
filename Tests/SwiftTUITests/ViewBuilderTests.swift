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
        #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → OptionalView<Text>
                      → Text:string("Hello World") (0, 0) 11x1
                """)
        }

        do {
            let (application, _) = try drawView(MyView(condition: false))
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → ConditionalView<Text, Text>
                      → Text:string("Hello World") (0, 0) 11x1
                """)
        }

        do {
            let (application, _) = try drawView(MyView(condition: false))
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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
            #expect(application.node?.treeDescription == """
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

}
