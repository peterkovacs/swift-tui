@MainActor
protocol Focusable: AnyObject {
    func becomeFirstResponder()
    func resignFirstResponder()

    var isFocused: Bool { get }
    var isFocusable: Bool { get }

    // TODO: Make this more generic and just be an "Event"
    /// Handle a Key event.
    /// - Parameter key: The recognized Key
    /// - Returns: `true` if the key was handled, otherwise `false`.
    ///
    /// When `false` is returned, the event will propagate up the node hierarchy to allow containing nodes to handle.
    func handle(key: Key) -> Bool

    var focusableElement: Visitor.FocusableElement { get }
}

extension Focusable where Self: Control {
    var focusableElement: Visitor.FocusableElement {
        .init(node: self) { [weak self] in
            self?.isFocusable ?? false
        } handle: { [weak self] key in
            self?.handle(key: key) ?? false
        } resignFirstResponder: { [weak self] in
            self?.resignFirstResponder()
        } becomeFirstResponder: { [weak self] in
            self?.becomeFirstResponder()
        }
    }
}
