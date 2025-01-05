@testable import SwiftTUI
import Testing

@Suite("Size Tests") @MainActor struct SizeTests {
    @Test func sizeOfSingleText() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
            }
        }

        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        let size = (node as? Control)?.size(proposedSize: .zero)

        #expect(size == .init(width: 5, height: 1))
    }

    @Test func sizeOfTwoTexts() async throws {
        struct MyView: View {
            var body: some View {
                Text("Hello")
                Text("World")
            }
        }

        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        let size = (node as? Control)?.size(proposedSize: .zero)

        #expect(size == .init(width: 5, height: 2))
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

        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        let size = (node as? Control)?.size(proposedSize: .zero)

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

        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        let size = (node as? Control)?.size(proposedSize: .zero)

        #expect(size == .init(width: 11, height: 1))
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

        let node = Application(root: MyView(), parser: .init(fileHandle: .nullDevice)).node
        let size = (node as? Control)?.size(proposedSize: .zero)

        #expect(size == .init(width: 16, height: 2))
    }

}
