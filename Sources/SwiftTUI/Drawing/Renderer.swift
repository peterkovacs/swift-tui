@MainActor
protocol Renderer: AnyObject {
    var application: Application? { get set }
    var window: CellGrid<Cell?> { get set }
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
         if rect == nil { invalidated = nil }
         let rect = rect ?? Rect(position: .zero, size: window.size)
         guard rect.size.width > 0, rect.size.height > 0 else {
             assertionFailure("Trying to draw in empty rect")
             return
         }

         for line in rect.minLine.intValue ... rect.maxLine.intValue {
             for column in rect.minColumn.intValue ... rect.maxColumn.intValue {
                 let position = Position(column: Extended(column), line: Extended(line))
                 if let cell = root.cell(at: position, covering: window[position]) {
                     drawPixel(cell, at: Position(column: Extended(column), line: Extended(line)))
                 }
             }
         }
    }
}
