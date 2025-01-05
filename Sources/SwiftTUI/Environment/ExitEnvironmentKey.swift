
enum Exit {
    static let (stream, continuation): (AsyncStream<Void>, AsyncStream<Void>.Continuation) = {
        let (stream, continuation) = AsyncStream<Void>.makeStream()

        return (stream, continuation)
    }()

    static func exit() {
        continuation.yield()
    }
}

extension EnvironmentValues {
    /// When called, will shut down the application.
    ///
    /// ```
    /// struct MyView: View {
    ///   @Enviornment(\.exit) var exit
    ///   var body: some View {
    ///     Button(exit) { Text("Exit") }
    ///   }
    /// }
    /// ```
    @MainActor public var exit: @Sendable () -> Void {
        get { self[ExitEnvironmentKey.self] }
        set { self[ExitEnvironmentKey.self] = newValue }
    }

    private struct ExitEnvironmentKey: EnvironmentKey {
        @MainActor static var defaultValue: @Sendable () -> Void = Exit.exit
    }
}
