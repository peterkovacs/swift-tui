import Observation
import SnapshotTesting
@testable import SwiftTUI
import Testing
import Synchronization

@MainActor
@Suite("Appearance Tests", .serialized) struct AppearanceTests {
    @Test func testOnAppearCalledWhenViewAppears() async throws {
        let appeared = Mutex(false)

        struct MyView: View {
            let appeared: @Sendable () -> Void
            var body: some View {
                Text("Hello")
                    .onAppear {
                        appeared()
                    }
            }
        }

        _ = try drawView(MyView { appeared.withLock { $0 = true } })

        #expect(appeared.withLock(\.self) == true)
    }

    @Test func testOnAppearNotCalledBeforeViewBuilds() async throws {
        let appeared = Mutex(false)

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
        _ = MyView { appeared.withLock { $0 = true } }
        #expect(appeared.withLock(\.self) == false)
    }

    @Observable
    class Model {
        var isShowing = true
    }

    @Test func testOnDisappearCalledWhenViewRemoved() async throws {
        let disappeared = Mutex(false)

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
            MyView(model: model) { disappeared.withLock { $0 = true } }
        )

        #expect(disappeared.withLock(\.self) == false)

        model.isShowing = false
        application.update()

        #expect(disappeared.withLock(\.self) == true)
    }

    @Test func testOnDisappearNotCalledWhenViewStaysVisible() async throws {
        let disappeared = Mutex(false)

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
            MyView(model: model) { disappeared.withLock { $0 = true } }
        )

        // The view with onDisappear is still visible — no callback yet
        #expect(disappeared.withLock(\.self) == false)

        // Trigger an unrelated update
        application.update()
        #expect(disappeared.withLock(\.self) == false)
    }

    @Test func testOnAppearAndOnDisappearBothFire() async throws {
        let appeared = Mutex(false)
        let disappeared = Mutex(false)

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
                   appeared: { appeared.withLock { $0 = true } },
                   disappeared: { disappeared.withLock { $0 = true } })
        )

        #expect(appeared.withLock(\.self) == true)
        #expect(disappeared.withLock(\.self) == false)

        model.isShowing = false
        application.update()

        #expect(disappeared.withLock(\.self) == true)
    }
}
