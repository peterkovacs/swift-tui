import Dependencies
import Foundation
import AsyncAlgorithms

@MainActor public class Application {
    private(set) var node: RootNode!
    private(set) var renderer: Renderer!
    let parser: KeyParser
    var invalidated: [(node: Node, frame: (Node) -> Rect)] = []


    init<T: View>(
        root: T,
        renderer: Renderer = TerminalRenderer(fileHandle: .standardOutput),
        parser: KeyParser = .init(fileHandle: .standardInput)
    ) {
        self.parser = parser
        self.node = nil
        self.node = RootNode(root: root, application: self)
        self.renderer = renderer
        self.renderer.application = self
    }

    func setup() {
        _ = node.layout(
            rect: .init(position: .zero, size: renderer.window.size)
        )
        node.focusManager?.defaultFocus()
        renderer.draw(rect: nil)
    }

    private let (invalidations, invalidate) = AsyncStream<Void>.makeStream()

    func invalidate(node: Node, frame: @escaping (Node) -> Rect) {
        invalidated.append((node, frame))
        invalidate.yield()
    }

    func update() {
        // It's possible that layout could invalidate nodes (e.g. GeometryReader)
        repeat {
            let invalidated = self.invalidated
            self.invalidated = []

            for (node, frame) in invalidated {
                renderer.invalidate(rect: frame(node))
                node.update(view: node.view)
            }

            _ = node.layout(
                rect: .init(position: .zero, size: renderer.window.size)
            )

            for (node, frame) in invalidated {
                renderer.invalidate(rect: frame(node))
            }
        } while !invalidated.isEmpty

        renderer.update()
    }
}

// Run Loop

extension Application {

    private func handleWindowSizeChange() {
        MainActor.assumeIsolated {
            renderer.setSize()
            node.invalidate()
            update()
        }
    }

    public func start() async throws {
        setup()

        let sigwinch: AsyncStream<Void> = {
            let stream = AsyncStream<Void>.makeStream()

            let sigWinChSource = LockIsolated(DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main))
            sigWinChSource.withValue { signal in
                signal.setEventHandler(
                    qos: .userInitiated,
                    flags: [],
                    handler: { [continuation = stream.continuation] in
                        continuation.yield()
                    }
                )
                signal.activate()
            }

            stream.continuation.onTermination = { _ in
                sigWinChSource.withValue { $0.cancel() }
            }

            return stream.stream
        }()


        let sigwinchTask = Task { @MainActor in
            for try await _ in sigwinch {
                self.handleWindowSizeChange()
            }
        }

        let keyInputTask = Task {
            for try await key in parser {
                if node.focusManager?.handle(key: key) == true {
                    continue
                }

                switch key {
                case Key(.char("l"), modifiers: .ctrl):
                    self.handleWindowSizeChange()

                case Key(.char("d"), modifiers: .ctrl):
                    Exit.exit()
                default:
                    break
                }
            }

            Exit.exit()
        }

        let invalidationsTask = Task {
            @Dependency(\.continuousClock) var continuousClock

            func updates<T: Clock>(stream: AsyncStream<Void>, clock: T) -> some AsyncSequence<Void, Never> where T.Duration == Duration {
                stream.debounce(for: .milliseconds(10), clock: clock)
            }

            for await _ in updates(stream: invalidations, clock: continuousClock) {
                self.update()
            }
        }

        for try await _ in Exit.stream {
            break
        }

        sigwinchTask.cancel()
        keyInputTask.cancel()
        invalidationsTask.cancel()
        renderer.stop()
    }

    func process(key: Key) {
        _ = node.focusManager?.handle(key: key)
        update()
    }

    func process(keys: String) {
        for byte in keys.unicodeScalars {
            process(key: .init(.char(byte)))
        }
    }

    func waitForTasksToComplete() async {
        func visit(node: Node) async {
            if let node = node as? Taskable, let task = node.task {
                await task.value
            }

            for child in node.children {
                await visit(node: child)
            }
        }

        await visit(node: node)
        update()
    }
}

// MARK: App

@MainActor public protocol App {
    associatedtype Body: View

    /// Top-level View of the Application
    @ViewBuilder var body: Body { get }

    init()
}

extension App {
    public static func main(_ arguments: [String]?) async throws {
        try await Application(root: Self().body).start()
    }

    public static func main() async throws {
        try await main(nil)
    }
}

