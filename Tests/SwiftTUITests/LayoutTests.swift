@testable import SwiftTUI
import Testing
import SnapshotTesting

@Suite("Size Tests") @MainActor struct SizeTests {
    let record = false

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
                    Text("1234567890")
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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
            of: application.node.frameDescription,
            as: .lines,
            record: record
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
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
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

        let (application, _) = try drawView(MyView())
        assertSnapshot(
            of: application.node.frameDescription,
            as: .lines,
            record: record
        )
    }
}
