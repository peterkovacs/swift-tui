import Foundation

@MainActor public class Application {
    private(set) var node: Node!
    // let renderer: Renderer
    let parser: KeyParser
    var invalidated: [Node] = []

    init<T: View>(
        root: T,
        parser: KeyParser
    ) {
        self.parser = parser
        self.node = Node.root(root, application: self)
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

        invalidated = []


    }
}
