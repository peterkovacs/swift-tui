import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing

@MainActor
@Suite("Appearance Tests", .serialized) struct AppearanceTests {
    @Test func testOnAppearCalledWhenViewAppears() async throws {
        let appeared = LockIsolated(false)

        struct MyView: View {
            let appeared: @Sendable () -> Void
            var body: some View {
                Text("Hello")
                    .onAppear {
                        appeared()
                    }
            }
        }

        _ = try drawView(MyView { appeared.withValue { $0 = true } })

        #expect(appeared.value)
    }

    @Test func testOnAppearNotCalledBeforeViewBuilds() async throws {
        let appeared = LockIsolated(false)

        struct MyView: View {
            let appeared: @Sendable () -> Void
            var body: some View {
                Text("Hello")
                    .onAppear {
                        appeared()
                    }
            }
        }

        // Just creating the view struct must not trigger onAppear
        _ = MyView { appeared.withValue { $0 = true } }
        #expect(!appeared.value)
    }

    @Observable
    class Model {
        var isShowing = true
    }

    @Test func testOnDisappearCalledWhenViewRemoved() async throws {
        let disappeared = LockIsolated(false)

        struct MyView: View {
            @State var model: Model
            let disappeared: @Sendable () -> Void
            var body: some View {
                if model.isShowing {
                    Text("Hello")
                        .onDisappear {
                            disappeared()
                        }
                }
            }
        }

        let model = Model()
        let (application, _) = try drawView(
            MyView(model: model) { disappeared.withValue { $0 = true } }
        )

        #expect(!disappeared.value)

        model.isShowing = false
        application.update()

        #expect(disappeared.value)
    }

    @Test func testOnDisappearNotCalledWhenViewStaysVisible() async throws {
        let disappeared = LockIsolated(false)

        struct MyView: View {
            @State var model: Model
            let disappeared: @Sendable () -> Void
            var body: some View {
                if model.isShowing {
                    Text("Hello")
                        .onDisappear {
                            disappeared()
                        }
                }
                Text("Always")
            }
        }

        let model = Model()
        let (application, _) = try drawView(
            MyView(model: model) { disappeared.withValue { $0 = true } }
        )

        // The view with onDisappear is still visible — no callback yet
        #expect(!disappeared.value)

        // Trigger an unrelated update
        application.update()
        #expect(!disappeared.value)
    }

    @Test func testOnAppearAndOnDisappearBothFire() async throws {
        let appeared = LockIsolated(false)
        let disappeared = LockIsolated(false)

        struct MyView: View {
            @State var model: Model
            let appeared: @Sendable () -> Void
            let disappeared: @Sendable () -> Void
            var body: some View {
                if model.isShowing {
                    Text("Hello")
                        .onAppear { appeared() }
                        .onDisappear { disappeared() }
                }
            }
        }

        let model = Model()
        let (application, _) = try drawView(
            MyView(model: model,
                   appeared: { appeared.withValue { $0 = true } },
                   disappeared: { disappeared.withValue { $0 = true } })
        )

        #expect(appeared.value)
        #expect(!disappeared.value)

        model.isShowing = false
        application.update()

        #expect(disappeared.value)
    }
}
