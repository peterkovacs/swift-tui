import Foundation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Text Tests", .snapshots(record: .failed)) struct TextTests {
    nonisolated let longText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        
        Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?
        
        At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
        """

    @Test func testLineBreak() {
        let lines = longText.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map { substring in
                substring.split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
                    .map { word in
                        (
                            word,
                            LineItemInput(
                                size: .init(word.count),
                                spacing: 1
                            )
                        )
                    }
            }

        #expect(lines.count == 5)
        #expect(lines.flatMap { $0.map(\.0.count) }.max() == 14)

        let lineSplitter = KnuthPlassLineBreaker()

        func wrap(lines: [[(ArraySlice<String.Element>.SubSequence, LineItemInput)]], size: Extended) -> String {
            let lines = lines.map { line in
                lineSplitter.wrapItemsToLines(items: line.map(\.1), in: size)
                    .map { wrapped in
                        var result = ""
                        for item in wrapped {
                            result.append(contentsOf: String(repeating: " ", count: item.leadingSpace.intValue))
                            result.append(contentsOf: line[item.index].0)
                        }
                        return result
                    }
            }

            return lines.map { $0.joined(separator: "\n") }.joined(separator: "\n")
        }

        // our minimum width is the size of the longest word == 14
        assertSnapshot(of: wrap(lines: lines, size: 14), as: .lines)
        assertSnapshot(of: wrap(lines: lines, size: 50), as: .lines)
        assertSnapshot(of: wrap(lines: lines, size: 100), as: .lines)
        assertSnapshot(of: wrap(lines: lines, size: .infinity), as: .lines)
    }

    @Test func testString() async throws {
        struct MyView: View {
            let text: String
            var body: some View {
                Text(text)
            }
        }

        let (application, _) = try drawView(MyView(text: longText))

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testTextLayoutInSingleLine() {

    }
}
