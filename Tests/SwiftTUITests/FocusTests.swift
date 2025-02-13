
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
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TextField:"" (0) FOCUSED (0, 0) 100x1
        
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
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TextField:"Goodbye World" (8) FOCUSED (0, 0) 100x1

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
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
              → TextField:"" (0) FOCUSED (0, 0) 100x1

        """)

        application.process(keys: "Hello World")
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 100x1

        """)

        model.items = [ "Hello", "World" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x3
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TextField}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"Hello" (5) (0, 0) 100x1
                → TextField:"World" (5) (0, 1) 100x1
              → TextField:"Hello World" (11) FOCUSED (0, 2) 100x1

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
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"" (0) FOCUSED (0, 0) 100x1
              → ForEach<Array<String>, String, TextField>

        """)

        application.process(keys: "Hello World")

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 100x1
              → ForEach<Array<String>, String, TextField>

        """)

        model.items = [ "Hello", "World" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x3
          → ComposedView<MyView>
            → TupleView<Pack{TextField, ForEach<Array<String>, String, TextField>}>
              → TextField:"Hello World" (11) FOCUSED (0, 0) 100x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Hello" (5) (0, 1) 100x1
                → TextField:"World" (5) (0, 2) 100x1

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
        → VStack<MyView> (0, 0) 100x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, FocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"A" (1) FOCUSED (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Bool>>
                → FocusView<TextField, Bool>
                  → TextField:"" (0) (0, 1) 100x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"B" (1) (0, 2) 100x1
                → TextField:"C" (1) (0, 3) 100x1
        
        """)

        await application.waitForTasksToComplete()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, FocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"A" (1) (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Bool>>
                → FocusView<TextField, Bool>
                  → TextField:"" (0) FOCUSED (0, 1) 100x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"B" (1) (0, 2) 100x1
                → TextField:"C" (1) (0, 3) 100x1

        """)

        model1.items = [ "X", "Y" ]
        model2.items = [ "Z" ]
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, FocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"X" (1) (0, 0) 100x1
                → TextField:"Y" (1) (0, 1) 100x1
              → TaskView<Int, FocusView<TextField, Bool>>
                → FocusView<TextField, Bool>
                  → TextField:"" (0) FOCUSED (0, 2) 100x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Z" (1) (0, 3) 100x1
        
        """)

        application.process(keys: "Hello World")

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x4
          → ComposedView<MyView>
            → TupleView<Pack{ForEach<Array<String>, String, TextField>, TaskView<Int, FocusView<TextField, Bool>>, ForEach<Array<String>, String, TextField>}>
              → ForEach<Array<String>, String, TextField>
                → TextField:"X" (1) (0, 0) 100x1
                → TextField:"Y" (1) (0, 1) 100x1
              → TaskView<Int, FocusView<TextField, Bool>>
                → FocusView<TextField, Bool>
                  → TextField:"Hello World" (11) FOCUSED (0, 2) 100x1
              → ForEach<Array<String>, String, TextField>
                → TextField:"Z" (1) (0, 3) 100x1
        
        """)
    }

    @Observable
    class Model2 {
        var isShowing = true
        var text: String = ""
        var text2: String = ""
    }

    @Test func testFocusedItemsIsRemoved() async throws {
        struct MyView: View {
            @State var model: Model2
            var body: some View {
                if model.isShowing {
                    TextField(text: $model.text) { _ in }
                }

                TextField(text: $model.text2) { _ in }
            }
        }

        let model = Model2()
        let (application, _) = try drawView(MyView(model: model))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{OptionalView<TextField>, TextField}>
              → OptionalView<TextField>
                → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TextField:"" (0) (0, 1) 100x1

        """)

        model.isShowing = false
        application.update()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x1
          → ComposedView<MyView>
            → TupleView<Pack{OptionalView<TextField>, TextField}>
              → OptionalView<TextField>
              → TextField:"" (0) FOCUSED (0, 0) 100x1

        """)
    }

    @Test func testTabChangesFocus() async throws {
        struct MyView: View {
            @State var text1: String = ""
            @State var text2: String = ""

            var body: some View {
                TextField(text: $text1) { _ in }
                TextField(text: $text2) { _ in }
            }
        }

        let (application, _) = try drawView(MyView())
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{TextField, TextField}>
              → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TextField:"" (0) (0, 1) 100x1

        """)

        application.process(key: .init(.tab))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{TextField, TextField}>
              → TextField:"" (0) (0, 0) 100x1
              → TextField:"" (0) FOCUSED (0, 1) 100x1

        """)

        application.process(key: .init(.tab))

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{TextField, TextField}>
              → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TextField:"" (0) (0, 1) 100x1

        """)

        application.process(key: .init(.tab, modifiers: .shift))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{TextField, TextField}>
              → TextField:"" (0) (0, 0) 100x1
              → TextField:"" (0) FOCUSED (0, 1) 100x1

        """)

        application.process(key: .init(.tab, modifiers: .shift))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{TextField, TextField}>
              → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TextField:"" (0) (0, 1) 100x1

        """)
    }

    @Test func setsFocusStateAccordingToFocus() async throws {
        struct MyView: View {
            enum Focus: Hashable {
                case text1, text2
            }

            @State var text1 = ""
            @State var text2 = ""

            @FocusState var focus: Focus? = nil

            var body: some View {
                TextField(text: $text1) { _ in }
                    .focus($focus, equals: .text1)
                TextField(text: $text2) { _ in }
                    .focus($focus, equals: .text2)
            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, FocusView<TextField, Optional<Focus>>}>
              → FocusView<TextField, Optional<Focus>>: text1 == text1
                → TextField:"" (0) FOCUSED (0, 0) 100x1
              → FocusView<TextField, Optional<Focus>>: text2 != text1
                → TextField:"" (0) (0, 1) 100x1
        
        """)

        application.process(key: .init(.tab))
        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, FocusView<TextField, Optional<Focus>>}>
              → FocusView<TextField, Optional<Focus>>: text1 != text2
                → TextField:"" (0) (0, 0) 100x1
              → FocusView<TextField, Optional<Focus>>: text2 == text2
                → TextField:"" (0) FOCUSED (0, 1) 100x1
        
        """)

    }

    @Test func setsFocusAccordingToFocusState() async throws {
        struct MyView: View {
            enum Focus: Hashable {
                case text1, text2
            }

            @State var text1 = ""
            @State var text2 = ""

            @FocusState var focus: Focus? = nil

            var body: some View {
                TextField(text: $text1) { _ in }
                    .focus($focus, equals: .text1)
                TextField(text: $text2) { _ in }
                    .focus($focus, equals: .text2)
                    .task { @MainActor in
                        focus = .text2
                    }

            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, TaskView<Int, FocusView<TextField, Optional<Focus>>>}>
              → FocusView<TextField, Optional<Focus>>: text1 == text1
                → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Optional<Focus>>>
                → FocusView<TextField, Optional<Focus>>: text2 != text1
                  → TextField:"" (0) (0, 1) 100x1
        
        """)

        await application.waitForTasksToComplete()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, TaskView<Int, FocusView<TextField, Optional<Focus>>>}>
              → FocusView<TextField, Optional<Focus>>: text1 != text2
                → TextField:"" (0) (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Optional<Focus>>>
                → FocusView<TextField, Optional<Focus>>: text2 == text2
                  → TextField:"" (0) FOCUSED (0, 1) 100x1
        
        """)

    }

    @Test func losesFocusWhenFocusStateSetToNil() async throws {
        struct MyView: View {
            enum Focus: Hashable {
                case text1, text2
            }

            @State var text1 = ""
            @State var text2 = ""

            @FocusState var focus: Focus? = nil

            var body: some View {
                TextField(text: $text1) { _ in }
                    .focus($focus, equals: .text1)
                TextField(text: $text2) { _ in }
                    .focus($focus, equals: .text2)
                    .task { @MainActor in
                        do {
                            try await Task.sleep(for: .milliseconds(100))
                            focus = nil
                        } catch {}
                    }

            }
        }

        let (application, _) = try drawView(MyView())

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, TaskView<Int, FocusView<TextField, Optional<Focus>>>}>
              → FocusView<TextField, Optional<Focus>>: text1 == text1
                → TextField:"" (0) FOCUSED (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Optional<Focus>>>
                → FocusView<TextField, Optional<Focus>>: text2 != text1
                  → TextField:"" (0) (0, 1) 100x1
        
        """)

        await application.waitForTasksToComplete()

        #expect(application.node.frameDescription == """
        → VStack<MyView> (0, 0) 100x2
          → ComposedView<MyView>
            → TupleView<Pack{FocusView<TextField, Optional<Focus>>, TaskView<Int, FocusView<TextField, Optional<Focus>>>}>
              → FocusView<TextField, Optional<Focus>>: text1 != (nil)
                → TextField:"" (0) (0, 0) 100x1
              → TaskView<Int, FocusView<TextField, Optional<Focus>>>
                → FocusView<TextField, Optional<Focus>>: text2 != (nil)
                  → TextField:"" (0) (0, 1) 100x1
        
        """)

    }
}
