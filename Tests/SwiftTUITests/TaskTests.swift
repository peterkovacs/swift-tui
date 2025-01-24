import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Task Tests") struct TaskTests {
    @Test func testTaskExecutes() async throws {
        struct MyView: View {
            let isCalled: @Sendable () -> Void
            var body: some View {
                Text("Hello, World!")
                    .task { isCalled() }
            }
        }

        let isCalled = LockIsolated(false)
        let (application, _) = try drawView(
            MyView {
                isCalled.withValue {
                    $0 = true
                }
            }
        )

        await Task.megaYield()
        #expect(isCalled.value == true)
    }

    @MainActor @Observable
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
                                try await Task.sleep(for: .seconds(1))
                            } catch is CancellationError {
                                isCalled()
                            } catch {}
                        }
                }
            }
        }

        let model = Model()
        let isCalled = LockIsolated(false)
        let (application, _) = try drawView(
            MyView(model: model) {
                isCalled.withValue {
                    $0 = true
                }
            }
        )

        #expect(isCalled.value == false)
        model.isShowing.toggle()

        #expect(!application.invalidated.isEmpty)
        application.update()

        // Give task time to actually cancel
        await Task.megaYield()

        #expect(isCalled.value == true)
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
        let isCalled = LockIsolated([Bool]())
        let (application, _) = try drawView(
            MyView(model: model) { value in
                isCalled.withValue {
                    $0.append(value)
                }
            }
        )

        // Give task time to start
        await Task.megaYield()

        #expect(isCalled.value == [true])
        model.isShowing.toggle()

        #expect(!application.invalidated.isEmpty)
        application.update()

        // Give task time to actually cancel
        await Task.megaYield()

        #expect(isCalled.value == [true, false])

    }
}
