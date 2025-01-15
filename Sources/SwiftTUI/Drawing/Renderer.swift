@MainActor
protocol Renderer: AnyObject {
    var application: Application? { get set }
    var window: Window<Cell?> { get set }
    var invalidated: Rect? { get set }

    func setSize()

//    /// Schedule an update to update any layers that have been invalidated.
//    func scheduleUpdate()
    /// Draw only the invalidated part of the layer.
    func update()
    /// Draw a specific area, or the entire layer if the area is nil.
    func draw(rect: Rect?)
    /// Terminate the Renderer
    func stop()

    func invalidate(rect: Rect)

    func drawPixel(_ cell: Cell?, at position: Position)
}

extension Renderer {
    /// Draw only the invalidated part of the layer.
    func update() {
        if let invalidated = invalidated {
            draw(rect: invalidated)
            self.invalidated = nil
        }
    }

    func invalidate(rect: Rect) {
        invalidated = invalidated?.union(rect) ?? rect
    }

    /// Draw a specific area, or the entire layer if the area is nil.
    func draw(rect: Rect? = nil) {
        guard let root = application?.node else { return }
        var newWindow: Window<Cell?>

        if let rect {
            newWindow = window
            rect.indices.forEach { newWindow[$0] = nil }
        } else {
            newWindow = .init(repeating: nil, size: window.size)
            invalidated = nil
        }

        let rect = rect ?? Rect(position: .zero, size: window.size)

        root.draw(rect: rect, into: &newWindow)

        for position in rect.indices {
            if newWindow[position] != window[position] {
                drawPixel(newWindow[position], at: position)
            }
        }
    }
}
