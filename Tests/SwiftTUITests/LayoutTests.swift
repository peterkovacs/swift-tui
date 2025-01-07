@testable import SwiftTUI
import Testing
import SnapshotTesting

@Suite("Size Tests") @MainActor struct SizeTests {
    @Test func sizeOfSingleText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }

        let (application, _) = try drawView(MyView())

        do {
            let size = (application.node as? Control)?.size(proposedSize: .zero)
            #expect(size == .init(width: 5, height: 1))
        }

        do {
            let size = (application.node as? Control)?.size(proposedSize: .init(width: 100, height: 100))
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

        let (application, _) = try drawView(MyView())
        let size = (application.node as? Control)?.size(proposedSize: .zero)

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

        let (application, _) = try drawView(MyView())

        do {
            let size = (application.node as? Control)?.size(proposedSize: .zero)
            #expect(size == .init(width: 5, height: 2))
        }

        do {
            let size = (application.node as? Control)?.size(proposedSize: .init(width: 100, height: 100))
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

        let (application, _) = try drawView(MyView())
        let size = (application.node as? Control)?.size(proposedSize: .zero)

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

        let (application, _) = try drawView(MyView())
        let size = (application.node as? Control)?.size(proposedSize: .zero)

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

        let (application, _) = try drawView(MyView())
        do {
            let size = (application.node as? Control)?.size(proposedSize: .zero)
            #expect(size == .init(width: 11, height: 1))
        }

        do {
            let size = (application.node as? Control)?.size(proposedSize: .init(width: 100, height: 100))
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

        let (application, _) = try drawView(MyView())
        let size = (application.node as? Control)?.size(proposedSize: .zero)

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

        let (application, _) = try drawView(MyView())
        do {
            let size = (application.node as? Control)?.size(proposedSize: .zero)
            #expect(size == .init(width: 16, height: 2))
        }

        do {
            let size = (application.node as? Control)?.size(proposedSize: .init(width: 100, height: 100))
            #expect(size == .init(width: 100, height: 100))
        }
    }

    @Test func layoutOfVStackLeading() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .leading) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfVStackLeadingWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .leading) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfVStackCenter() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .center) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfVStackCenterWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .center) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfVStackTrailing() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .trailing) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfVStackTrailingWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                VStack(alignment: .trailing) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }


    @Test func layoutOfHStackTop() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .top) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfHStackTopWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .top) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfHStackCenter() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .center) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfHStackCenterWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .center) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfHStackBottom() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .bottom) {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
        )
    }

    @Test func layoutOfHStackBottomWithSpacer() async throws {
        struct MyView: View {
            var body: some View {
                HStack(alignment: .bottom) {
                    Text("Hello")
                    Spacer()
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription, as: .lines
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(of: application.node.frameDescription, as: .lines)
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(of: application.node.frameDescription, as: .lines)
    }
}
