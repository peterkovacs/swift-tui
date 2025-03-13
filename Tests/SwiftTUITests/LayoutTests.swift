import InlineSnapshotTesting
import SnapshotTesting
@testable import SwiftTUI
import Testing

@Suite("Layout Tests", .snapshots(record: .missing)) @MainActor struct LayoutTests {
    let record = false

    @Test func sizeOfSingleText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))

        do {
            let size = application.node.size(proposedSize: .zero)
            #expect(size == .init(width: 5, height: 1))
        }

        do {
            let size = application.node.size(proposedSize: .init(width: 100, height: 100))
            #expect(size == .init(width: 5, height: 1))
        }
    }

    @Test func sizeOfTwoTexts() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                Text("World")
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        let size = application.node.size(proposedSize: .zero)

        #expect(size == .init(width: 5, height: 2))
    }

    @Test func sizeOfTwoTextsWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                Spacer()
                Text("World")
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))

        do {
            let size = application.node.size(proposedSize: .zero)
            #expect(size == .init(width: 5, height: 2))
        }

        do {
            let size = application.node.size(proposedSize: .init(width: 100, height: 100))
            #expect(size == .init(width: 5, height: 100))
        }
    }


    @Test func sizeOfEmbeddedVStack() async throws {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        let size = application.node.size(proposedSize: .zero)

        #expect(size == .init(width: 5, height: 2))
    }

    @Test func sizeOfHStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        let size = application.node.size(proposedSize: .zero)

        #expect(size == .init(width: 11, height: 1))
    }

    @Test func sizeOfHStackWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        do {
            let size = application.node.size(proposedSize: .zero)
            #expect(size == .init(width: 11, height: 1))
        }

        do {
            let size = application.node.size(proposedSize: .init(width: 100, height: 100))
            #expect(size == .init(width: 100, height: 1))

        }
    }

    @Test func sizeOfHStackContainingVStack() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    VStack {
                        Text("Hello")
                        Text("World")
                    }

                    VStack {
                        Text("1234567890")
                        Text("1234567890")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        let size = application.node.size(proposedSize: .zero)

        #expect(size == .init(width: 16, height: 2))
    }

    @Test func sizeOfHStackContainingVStackWithSpacers() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Spacer()

                    VStack {
                        Text("1234567890")
                        Spacer()
                        Text("1234567890")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        do {
            let size = application.node.size(proposedSize: .zero)
            #expect(size == .init(width: 16, height: 2))
        }

        do {
            let size = application.node.size(proposedSize: .init(width: 100, height: 100))
            #expect(size == .init(width: 100, height: 100))
        }
    }

    @Test func sizeOfZStack() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        let size = application.node.size(proposedSize: .zero)

        #expect(size == .init(width: 5, height: 1))
    }


    @Test func layoutOfVStackLeading() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .leading) {
                    Text("1234567890")
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x3
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Text}>> (0, 0) 10x3
                  → TupleView<Pack{Text, Text, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (0, 1) 5x1
                    → Text:string("World") (0, 2) 5x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfVStackLeadingWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .leading) {
                    Text("1234567890")
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x20
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Spacer, Text}>> (0, 0) 10x20
                  → TupleView<Pack{Text, Text, Spacer, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (0, 1) 5x1
                    → Spacer (0, 2) 1x17
                    → Text:string("World") (0, 19) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfVStackCenter() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .center) {
                    Text("1234567890")
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x3
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Text}>> (0, 0) 10x3
                  → TupleView<Pack{Text, Text, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (2, 1) 5x1
                    → Text:string("World") (2, 2) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfVStackCenterWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .center) {
                    Text("1234567890")
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x20
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Spacer, Text}>> (0, 0) 10x20
                  → TupleView<Pack{Text, Text, Spacer, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (2, 1) 5x1
                    → Spacer (4, 2) 1x17
                    → Text:string("World") (2, 19) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfVStackTrailing() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .trailing) {
                    Text("1234567890")
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x3
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Text}>> (0, 0) 10x3
                  → TupleView<Pack{Text, Text, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (5, 1) 5x1
                    → Text:string("World") (5, 2) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfVStackTrailingWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .trailing) {
                    Text("1234567890")
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 10x20
              → ComposedView<MyView>
                → VStack<TupleView<Pack{Text, Text, Spacer, Text}>> (0, 0) 10x20
                  → TupleView<Pack{Text, Text, Spacer, Text}>
                    → Text:string("1234567890") (0, 0) 10x1
                    → Text:string("Hello") (5, 1) 5x1
                    → Spacer (9, 2) 1x17
                    → Text:string("World") (5, 19) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }


    @Test func layoutOfHStackTop() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .top) {
                    VStack {
                        Text("Hello")
                        Text("World")
                    }
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 17x2
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Text}>>, Text, Text}>> (0, 0) 17x2
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Text}>>, Text, Text}>
                    → VStack<TupleView<Pack{Text, Text}>> (0, 0) 5x2
                      → TupleView<Pack{Text, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Text:string("World") (0, 1) 5x1
                    → Text:string("Hello") (6, 0) 5x1
                    → Text:string("World") (12, 0) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackTopWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .top) {
                    VStack {
                        Text("Hello")
                        Text("World")
                    }

                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x2
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Text}>>, Text, Spacer, Text}>> (0, 0) 50x2
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Text}>>, Text, Spacer, Text}>
                    → VStack<TupleView<Pack{Text, Text}>> (0, 0) 5x2
                      → TupleView<Pack{Text, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Text:string("World") (0, 1) 5x1
                    → Text:string("Hello") (6, 0) 5x1
                    → Spacer (12, 0) 32x1
                    → Text:string("World") (45, 0) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackCenter() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .center) {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 17x20
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Text}>> (0, 0) 17x20
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Text}>
                    → VStack<TupleView<Pack{Text, Spacer, Text}>> (0, 0) 5x20
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Spacer (2, 1) 1x18
                        → Text:string("World") (0, 19) 5x1
                    → Text:string("Hello") (6, 9) 5x1
                    → Text:string("World") (12, 9) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackCenterWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .center) {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x20
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Spacer, Text}>> (0, 0) 50x20
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Spacer, Text}>
                    → VStack<TupleView<Pack{Text, Spacer, Text}>> (0, 0) 5x20
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Spacer (2, 1) 1x18
                        → Text:string("World") (0, 19) 5x1
                    → Text:string("Hello") (6, 9) 5x1
                    → Spacer (12, 9) 32x1
                    → Text:string("World") (45, 9) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackBottom() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .bottom) {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 17x20
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Text}>> (0, 0) 17x20
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Text, Text}>
                    → VStack<TupleView<Pack{Text, Spacer, Text}>> (0, 0) 5x20
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Spacer (2, 1) 1x18
                        → Text:string("World") (0, 19) 5x1
                    → Text:string("Hello") (6, 19) 5x1
                    → Text:string("World") (12, 19) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackBottomWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .bottom) {
                    VStack {
                        Text("1")
                        Text("2")
                        Text("3")
                    }
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x3
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Text, Text}>>, Text, Spacer, Text}>> (0, 0) 50x3
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Text, Text}>>, Text, Spacer, Text}>
                    → VStack<TupleView<Pack{Text, Text, Text}>> (0, 0) 1x3
                      → TupleView<Pack{Text, Text, Text}>
                        → Text:string("1") (0, 0) 1x1
                        → Text:string("2") (0, 1) 1x1
                        → Text:string("3") (0, 2) 1x1
                    → Text:string("Hello") (2, 2) 5x1
                    → Spacer (8, 2) 36x1
                    → Text:string("World") (45, 2) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStackContainingVStacksAndSpacers() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    VStack {
                        Text("Hello")
                        Spacer()
                        Text("World")
                    }

                    Spacer()

                    VStack {
                        Text("1234567890")
                        Spacer()
                        Text("1234567890")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x20
              → ComposedView<MyView>
                → HStack<TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Spacer, VStack<TupleView<Pack{Text, Spacer, Text}>>}>> (0, 0) 50x20
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Spacer, Text}>>, Spacer, VStack<TupleView<Pack{Text, Spacer, Text}>>}>
                    → VStack<TupleView<Pack{Text, Spacer, Text}>> (0, 0) 5x20
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Spacer (2, 1) 1x18
                        → Text:string("World") (0, 19) 5x1
                    → Spacer (6, 9) 33x1
                    → VStack<TupleView<Pack{Text, Spacer, Text}>> (40, 0) 10x20
                      → TupleView<Pack{Text, Spacer, Text}>
                        → Text:string("1234567890") (40, 0) 10x1
                        → Spacer (44, 1) 1x18
                        → Text:string("1234567890") (40, 19) 10x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfHStacksContainingSpacers() async throws {
        struct MyView: View {
            var body: some View {
                HStack {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }

                Spacer()

                HStack {
                    Text("1234567890")
                    Spacer()
                    Text("1234567890")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 50x20
              → ComposedView<MyView>
                → TupleView<Pack{HStack<TupleView<Pack{Text, Spacer, Text}>>, Spacer, HStack<TupleView<Pack{Text, Spacer, Text}>>}>
                  → HStack<TupleView<Pack{Text, Spacer, Text}>> (0, 0) 50x1
                    → TupleView<Pack{Text, Spacer, Text}>
                      → Text:string("Hello") (0, 0) 5x1
                      → Spacer (6, 0) 38x1
                      → Text:string("World") (45, 0) 5x1
                  → Spacer (24, 1) 1x18
                  → HStack<TupleView<Pack{Text, Spacer, Text}>> (0, 19) 50x1
                    → TupleView<Pack{Text, Spacer, Text}>
                      → Text:string("1234567890") (0, 19) 10x1
                      → Spacer (11, 19) 28x1
                      → Text:string("1234567890") (40, 19) 10x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStack() async throws {
        struct MyView: View {
            var body: some View {
                ZStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x1
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, Text}>> (0, 0) 5x1
                  → TupleView<Pack{Text, Text}>
                    → Text:string("Hello") (0, 0) 5x1
                    → Text:string("World") (0, 0) 5x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackTopLeading() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .topLeading) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 0) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (0, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (0, 0) 1x1
                        → Text:string("o") (0, 1) 1x1
                        → Text:string("r") (0, 2) 1x1
                        → Text:string("l") (0, 3) 1x1
                        → Text:string("d") (0, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackTop() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .top) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 0) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (2, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (2, 0) 1x1
                        → Text:string("o") (2, 1) 1x1
                        → Text:string("r") (2, 2) 1x1
                        → Text:string("l") (2, 3) 1x1
                        → Text:string("d") (2, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackTopTrailing() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .topTrailing) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 0) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (4, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (4, 0) 1x1
                        → Text:string("o") (4, 1) 1x1
                        → Text:string("r") (4, 2) 1x1
                        → Text:string("l") (4, 3) 1x1
                        → Text:string("d") (4, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackLeading() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Hello")
                        Divider()
                        Text("World")
                    }

                    Text("-->")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x3
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Text}>> (0, 0) 5x3
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Text}>
                    → VStack<TupleView<Pack{Text, Divider, Text}>> (0, 0) 5x3
                      → TupleView<Pack{Text, Divider, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Divider (0, 1) 5x1
                        → Text:string("World") (0, 2) 5x1
                    → Text:string("-->") (0, 1) 3x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackTrailing() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .trailing) {
                    VStack(alignment: .trailing) {
                        Text("Hello")
                        Divider()
                        Text("World")
                    }

                    Text("<--")
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x3
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Text}>> (0, 0) 5x3
                  → TupleView<Pack{VStack<TupleView<Pack{Text, Divider, Text}>>, Text}>
                    → VStack<TupleView<Pack{Text, Divider, Text}>> (0, 0) 5x3
                      → TupleView<Pack{Text, Divider, Text}>
                        → Text:string("Hello") (0, 0) 5x1
                        → Divider (0, 1) 5x1
                        → Text:string("World") (0, 2) 5x1
                    → Text:string("<--") (2, 1) 3x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackBottomLeading() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .bottomLeading) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 4) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (0, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (0, 0) 1x1
                        → Text:string("o") (0, 1) 1x1
                        → Text:string("r") (0, 2) 1x1
                        → Text:string("l") (0, 3) 1x1
                        → Text:string("d") (0, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackBottom() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .bottom) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 4) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (2, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (2, 0) 1x1
                        → Text:string("o") (2, 1) 1x1
                        → Text:string("r") (2, 2) 1x1
                        → Text:string("l") (2, 3) 1x1
                        → Text:string("d") (2, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func layoutOfZStackBottomTrailing() async throws {
        struct MyView: View {
            var body: some View {
                ZStack(alignment: .bottomTrailing) {
                    Text("Hello")

                    VStack {
                        Text("W")
                        Text("o")
                        Text("r")
                        Text("l")
                        Text("d")
                    }
                }
            }
        }

        let (application, _) = try drawView(MyView(), size: .init(width: 50, height: 20))
        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 5x5
              → ComposedView<MyView>
                → ZStack<TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>> (0, 0) 5x5
                  → TupleView<Pack{Text, VStack<TupleView<Pack{Text, Text, Text, Text, Text}>>}>
                    → Text:string("Hello") (0, 4) 5x1
                    → VStack<TupleView<Pack{Text, Text, Text, Text, Text}>> (4, 0) 1x5
                      → TupleView<Pack{Text, Text, Text, Text, Text}>
                        → Text:string("W") (4, 0) 1x1
                        → Text:string("o") (4, 1) 1x1
                        → Text:string("r") (4, 2) 1x1
                        → Text:string("l") (4, 3) 1x1
                        → Text:string("d") (4, 4) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }


}
