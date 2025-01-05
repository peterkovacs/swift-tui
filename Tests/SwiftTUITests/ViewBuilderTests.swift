import Testing
@testable import SwiftTUI

@MainActor
@Suite("ViewBuilder") struct ViewBuilderTests {

    @Test func buildEmpty() async throws {
        struct MyView: View {
            var body: some View {
                let _ = ()
            }
        }
        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        #expect(node?.treeDescription == """
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
            let node = Application(root: MyView(condition: true), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → OptionalView<Text>
                      → Text
                """)
        }

        do {
            let node = Application(root: MyView(condition: false), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
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
            let node = Application(root: MyView(condition: true), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → ConditionalView<Text, Text>
                      → Text
                """)
        }

        do {
            let node = Application(root: MyView(condition: false), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → ConditionalView<Text, Text>
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text}>
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text}>
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
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
            let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
            #expect(node?.treeDescription == """
                → VStack<MyView>
                  → ComposedView<MyView>
                    → TupleView<Pack{Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text, Text}>
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                      → Text
                """)
        }
    }

}
