
import Dependencies
import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Focus Tests", .snapshots(record: .missing)) struct FocusTests {
    @Test func testBasicDefaultFocus() async throws {
        struct MyView: View {
            @State var string: String = ""

            var body: some View {
                TextField(text: $string) { _ in }
            }
        }

        
        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 1x1
          → ComposedView<MyView>
            → TextField:"" (0) FOCUSED (0, 0) 1x1

        """)

        let clock = TestClock()
        let handle = withDependencies {
            $0.continuousClock = clock
        } operation: {
            Task { try await application.start() }
        }

        application.process(keys: "Hello World")
        application.process(key: .init(.left, modifiers: .ctrl))
        application.process(key: .init("w", modifiers: .ctrl))
        application.process(keys: "Goodbye ")

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 14x1
          → ComposedView<MyView>
            → TextField:"Goodbye World" (8) FOCUSED (0, 0) 14x1

        """)

        _ = handle
    }

    @Observable
    class Model {
        var items: [String]

        init(items: [String]) {
            self.items = items
        }
    }

    @Test func testItemsInsertedBeforeFocus() async throws {
        struct MyView: View {
            @State var string: String = ""
            @State var items: Model

            var body: some View {
                ForEach(items.items, id: \.self) { item in
                    TextField(
                        text: .init(get: { item }, set: { _ in })
                    ) { _ in }
                }

                TextField(text: $string) { _ in }
            }
        }

        let model = Model(items: [])
        let (application, _) = try drawView(MyView(items: model))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 1x1
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
              → TextField:"" (0) FOCUSED (0, 0) 1x1

        """)

        application.process(keys: "Hello World")
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 12x1
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 12x1

        """)

        model.items = [ "Hello", "World" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 12x3
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"Hello" (5) (3, 0) 6x1
                → TextField:"World" (5) (3, 1) 6x1
              → TextField:"Hello World" (11) FOCUSED (0, 2) 12x1

        """)

        #expect((application.focusManager.focusedElement?.node as? TextFieldNode)?.description == #"TextField:"Hello World" (11) FOCUSED"#)
    }

    @Test func testItemsInsertedAfterFocus() async throws {
        struct MyView: View {
            @State var string: String = ""
            @State var items: Model

            var body: some View {
                TextField(text: $string) { _ in }

                ForEach(items.items, id: \.self) { item in
                    TextField(
                        text: .init(get: { item }, set: { _ in })
                    ) { _ in }
                }
            }
        }

        let model = Model(items: [])
        let (application, _) = try drawView(MyView(items: model))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 1x1
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"" (0) FOCUSED (0, 0) 1x1
              → ForEach<Array<String>, String, TextField>

        """)

        application.process(keys: "Hello World")

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 12x1
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 12x1
              → ForEach<Array<String>, String, TextField>

        """)

        model.items = [ "Hello", "World" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 12x3
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 12x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Hello" (5) (3, 1) 6x1
                → TextField:"World" (5) (3, 2) 6x1

        """)

        #expect((application.focusManager.focusedElement?.node as? TextFieldNode)?.description == #"TextField:"Hello World" (11) FOCUSED"#)
    }

    @Test func testItemsRemovedAndAddedAroundFocus() async throws {
        struct MyView: View {
            @FocusState var isFocused
            @State var model1: Model
            @State var model2: Model
            @State var text = ""
            var body: some View {
                ForEach(model1.items, id: \.self) { item in
                    TextField(text: .init(get: { item }, set: { _ in })) { _ in }
                }

                TextField(text: $text) { _ in }
                    .focus($isFocused)
                    .task { @MainActor in
                        isFocused = true
                    }

                ForEach(model2.items, id: \.self) { item in
                    TextField(text: .init(get: { item }, set: { _ in })) { _ in }
                }
            }
        }

        let (model1, model2) = (Model(items: ["A"]), Model(items: ["B", "C"]))
        let (application, _) = try drawView(MyView(model1: model1, model2: model2))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 2x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, SetFocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"A" (1) FOCUSED (0, 0) 2x1
              → TaskView<Int, SetFocusView<TextField, Bool>>
                → SetFocusView<TextField, Bool>
                  → TextField:"" (0) (0, 1) 1x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"B" (1) (0, 2) 2x1
                → TextField:"C" (1) (0, 3) 2x1
        
        """)

        await application.waitForTasksToComplete()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 2x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, SetFocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"A" (1) (0, 0) 2x1
              → TaskView<Int, SetFocusView<TextField, Bool>>
                → SetFocusView<TextField, Bool>
                  → TextField:"" (0) FOCUSED (0, 1) 1x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"B" (1) (0, 2) 2x1
                → TextField:"C" (1) (0, 3) 2x1

        """)

        model1.items = [ "X", "Y" ]
        model2.items = [ "Z" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 2x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, SetFocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"X" (1) (0, 0) 2x1
                → TextField:"Y" (1) (0, 1) 2x1
              → TaskView<Int, SetFocusView<TextField, Bool>>
                → SetFocusView<TextField, Bool>
                  → TextField:"" (0) FOCUSED (0, 2) 1x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Z" (1) (0, 3) 2x1

        """)

        application.process(keys: "Hello World")

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 12x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, SetFocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"X" (1) (5, 0) 2x1
                → TextField:"Y" (1) (5, 1) 2x1
              → TaskView<Int, SetFocusView<TextField, Bool>>
                → SetFocusView<TextField, Bool>
                  → TextField:"Hello World" (11) FOCUSED (0, 2) 12x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Z" (1) (5, 3) 2x1
        
        """)

    }
}
