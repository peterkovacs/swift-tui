@testable import SwiftTUI
import Testing
import SnapshotTesting
import InlineSnapshotTesting

@MainActor @Suite("ZStack Tests", .snapshots(record: .missing)) struct ZStackTests {
    @Test func rendersFrontToBack() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    VStack {
                        Text("Hello")
                        Text("World")
                        Text("01234")
                    }

                    VStack {
                        Text("ABC")
                    }

                    Text("X")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x3
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{VStack<TupleView<Pack{Text, Text, Text}>>, VStack<Text>, Text}>> (0, 0) 5x3
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Text, Text}>>, VStack<Text>, Text}>
                    → VStack<TupleView<Pack{Text, Text, Text}>> (0, 0) 5x3
                      → TupleView<Pack{Text, Text, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Text:string("World") (0, 1) 5x1
                        → Text:string("01234") (0, 2) 5x1
                    → VStack<Text> (1, 1) 3x1
                      → Text:string("ABC") (1, 1) 3x1
                    → Text:string("X") (2, 1) 1x1

            """
        }
        assertSnapshot(of: application.renderer, as: .rendered)
    }

    @Test func hitTest() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    VStack {
                        Text("Hello")
                        Text("World")
                        Text("01234")
                    }

                    VStack {
                        Text("ABC")
                    }

                    Text("X")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertInlineSnapshot(of: application.node.hitTest(at: .init(column: 2, line: 1), key: .init(.mouseUp(button: 0, at: .init(column: 2, line: 1)))), as: .frameDescription) {
            """
            → Text:string("X") (2, 1) 1x1

            """
        }
        assertInlineSnapshot(of: application.node.hitTest(at: .init(column: 1, line: 1), key: .init(.mouseUp(button: 0, at: .init(column: 1, line: 1)))), as: .frameDescription) {
            """
            → Text:string("ABC") (1, 1) 3x1

            """
        }
        assertInlineSnapshot(of: application.node.hitTest(at: .init(column: 0, line: 1), key: .init(.mouseUp(button: 0, at: .init(column: 0, line: 1)))), as: .frameDescription) {
            """
            → Text:string("World") (0, 1) 5x1

            """
        }
    }
}
