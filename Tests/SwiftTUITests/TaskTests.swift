import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing
import Synchronization

@MainActor
@Suite("Task Tests", .serialized) struct TaskTests {
    @Test func testTaskExecutes() async throws {
        struct MyView: View {
            let isCalled: @Sendable () -> Void
            var body: some View {
                Text("Hello, World!")
                    .task { isCalled() }
            }
        }

        let isCalled = Mutex(false)
        let (application, _) = try drawView(
            MyView {
                isCalled.withLock {
                    $0 = true
                }
            }
        )

        await application.waitForTasksToComplete()
        #expect(isCalled.withLock(\.self) == true)
    }

    @Observable
    class Model {
        var isShowing = true
    }

    @Test func testTaskIsCancelled() async throws {
        struct MyView: View {
            @State var model: Model
            let isCalled: @Sendable () -> Void
            var body: some View {
                if model.isShowing {
                    Text("Hello, World!")
                        .task {
                            do {
                                try await Task.sleep(for: .seconds(60))
                            } catch is CancellationError {
                                isCalled()
                            } catch {}
                        }
                }
            }
        }

        let model = Model()
        let isCalled = Mutex(false)
        let (application, _) = try drawView(
            MyView(model: model) {
                isCalled.withLock {
                    $0 = true
                }
            }
        )

        #expect(isCalled.withLock(\.self) == false)
        model.isShowing.toggle()

        #expect(!application.invalidated.isEmpty)
        application.update()

        // Give task time to actually cancel
        await application.waitForTasksToComplete()
        // Give time for our code to get called?
        await Task.megaYield()

        #expect(isCalled.withLock(\.self) == true)
    }

    @Test func testTaskIsRestartedWhenIDChanges() async throws {
        struct MyView: View {
            @State var model: Model
            let isCalled: @Sendable (Bool) -> Void
            var body: some View {
                Text("Hello, World!")
                    // TODO: Fix Sendable requirements of Tasks
                    .task(id: model.isShowing) { @MainActor in
                        isCalled(model.isShowing)
                    }
            }
        }

        let model = Model()
        let isCalled = Mutex([Bool]())
        let (application, _) = try drawView(
            MyView(model: model) { value in
                isCalled.withLock {
                    $0.append(value)
                }
            }
        )

        // Give task time to start
        await application.waitForTasksToComplete()

        #expect(isCalled.withLock(\.self) == [true])
        model.isShowing.toggle()

        #expect(!application.invalidated.isEmpty)
        application.update()

        // Give task time to actually cancel
        await application.waitForTasksToComplete()

        #expect(isCalled.withLock(\.self) == [true, false])

    }
}
