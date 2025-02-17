import Foundation
import InlineSnapshotTesting
import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("ForEach Tests", .snapshots(record: .missing)) struct ForEachTests {
    let record = false
    @Test func testRendersStaticArray() async throws {
        struct MyView: View {
            var body: some View {
                ForEach([1, 2, 3], id: \.self) { item in
                    Text("\(item)")
                }
            }
        }

        let (application, _) = try drawView(MyView())

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x3
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Observable
    class Model<Element> {
        var data: [Element]

        init(data: [Element]) {
            self.data = data
        }
    }

    @Test func testUpdatesFromObservationWithAppend() async throws {
        struct MyView: View {
            @State var model: Model<Int>
            var body: some View {
                ForEach(model.data, id: \.self) { item in
                    Text("\(item)")
                }
            }
        }

        let model = Model<Int>(data: [1, 2, 3])
        let (application, _) = try drawView(MyView(model: model))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x3
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1

            """
        }

        model.data.append(4)
        #expect(application.invalidated.count == 1)
        #expect(application.invalidated.first?.node === application.node.children[0])
        application.update()

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x4
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1
                  → Text:string("4") (0, 3) 1x1

            """
        }

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testUpdatesFromObservationWithRemove() async throws {
        struct MyView: View {
            @State var model: Model<Int>
            var body: some View {
                ForEach(model.data, id: \.self) { item in
                    Text("\(item)")
                }
            }
        }

        let model = Model<Int>(data: [1, 2, 3])
        let (application, _) = try drawView(MyView(model: model))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x3
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1

            """
        }

        model.data = [1, 2]
        #expect(application.invalidated.count == 1)
        #expect(application.invalidated.first?.node === application.node.children[0])
        application.update()

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x2
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testUpdatesFromObservationWithModify() async throws {
        struct MyView: View {
            @State var model: Model<Int>
            var body: some View {
                ForEach(model.data, id: \.self) { item in
                    Text("\(item)")
                }
            }
        }

        let model = Model<Int>(data: [1, 2, 3])
        let (application, _) = try drawView(MyView(model: model))

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x3
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("2") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1

            """
        }

        model.data = [1, 4, 3]
        #expect(application.invalidated.count == 1)
        #expect(application.invalidated.first?.node === application.node.children[0])
        application.update()

        assertInlineSnapshot(of: application, as: .frameDescription) {
            """
            → VStack<MyView> (0, 0) 1x3
              → ComposedView<MyView>
                → ForEach<Array<Int>, Int, Text>
                  → Text:string("1") (0, 0) 1x1
                  → Text:string("4") (0, 1) 1x1
                  → Text:string("3") (0, 2) 1x1

            """
        }
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )
    }

    @Test func testCalendar() async throws {
        struct CalendarView: View {
            @State var model: Model<Int>
            let calendar: Calendar

            init(model: Model<Int>, calendar: Calendar = .current) {
                self.model = model
                self.calendar = calendar
            }

            @ViewBuilder
            func calendar(index: Int) -> some View {
                let monthOffset = calendar.component(.weekday, from: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1).date!)
                let day = index - monthOffset + 1
                let date = DateComponents(calendar: calendar, year: 2025, month: 1, day: day).date!
                
                if index < monthOffset {
                    Text("  ")
                        .frame(width: 2, height: 1, alignment: .trailing)
                } else if calendar.component(.month, from: date) == 1 {
                    Text(String(format: "%2d", day))
                        .frame(width: 2, height: 1, alignment: .trailing)
                        .underline(model.data[calendar.component(.weekday, from: date)] % 2 == 0)
                        .bold(model.data[calendar.component(.weekday, from: date)] % 2 == 0)
                        .foregroundColor( model.data[calendar.component(.weekday, from: date)] % 2 != 0 ? .gray : .default)
                } else {
                    Text("  ")
                        .frame(width: 2, height: 1, alignment: .trailing)
                }
            }

            var body: some View {
                VStack {
                    HStack(spacing: 1) {
                        Text("Su")
                        Text("Mo")
                        Text("Tu")
                        Text("We")
                        Text("Th")
                        Text("Fr")
                        Text("Sa")
                    }
                    HStack(spacing: 1) {
                        ForEach(1...7, id: \.self) { index in
                            calendar(index: index)
                        }
                    }
                    .frame(width: 20, height: 1)

                    HStack(spacing: 1) {
                        ForEach(8...14, id: \.self) { index in
                            calendar(index: index)
                        }
                    }
                    .frame(width: 20, height: 1)

                    HStack(spacing: 1) {
                        ForEach(15...21, id: \.self) { index in
                            calendar(index: index)
                        }
                    }
                    .frame(width: 20, height: 1)

                    HStack(spacing: 1) {
                        ForEach(22...28, id: \.self) { index in
                            calendar(index: index)
                        }
                    }
                    .frame(width: 20, height: 1)

                    HStack(spacing: 1) {
                        ForEach(29...35, id: \.self) { index in
                            calendar(index: index)
                        }
                    }
                    .frame(width: 20, height: 1)
                }
                .frame(width: 20, height: 6)
            }
        }

        let model = Model(data: [0, 1, 2, 3, 4, 5, 6, 7 ])

        let (application, _) = try drawView(CalendarView(model: model, calendar: .current))

        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

        model.data = [7, 0, 1, 2, 3, 4, 5, 6]
        application.update()
        assertSnapshot(
            of: application.renderer,
            as: .rendered
        )

    }
}
