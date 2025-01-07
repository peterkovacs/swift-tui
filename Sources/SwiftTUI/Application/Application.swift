import Foundation

@MainActor public class Application {
    private(set) var node: Node!
    private(set) var renderer: Renderer!
    let parser: KeyParser
    var invalidated: [Node] = []

    init<T: View>(
        root: T,
        renderer: Renderer = TerminalRenderer(fileHandle: .standardOutput),
        parser: KeyParser = .init(fileHandle: .standardInput)
    ) {
        self.parser = parser
        self.node = Node.root(root, application: self)
        self.renderer = renderer
        self.renderer.application = self
    }

    func setup() {
        _ = node.layout(size: renderer.window.size)
        renderer.draw(rect: nil)
    }

    func invalidate(node: Node) {
        invalidated.append(node)
        scheduleUpdate()
    }

    var updateScheduled = false
    func scheduleUpdate() {
        if !updateScheduled {
            updateScheduled = true
            Task { self.update() }
        }
    }

    func update() {
        updateScheduled = false

        for node in invalidated {
            node.update(view: node.view)
        }

        _ = node.layout(size: renderer.window.size)

        for node in invalidated {
            renderer.invalidate(rect: node.frame)
        }

        invalidated = []
        renderer.update()
    }
}
