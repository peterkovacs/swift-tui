/// This is the interface to any view as the view graph is concerned.
///
/// Such a generic view can be either a `PrimitiveView`, meaning it has custom logic to build
/// and update the nodes, or a `ComposedView`, meaning it is created using the familiar `View`
/// struct.

protocol GenericView: Sendable {
    /// Construct a Node hierarchy for this view and any child (i.e. body) elements it might represent.
    ///
    /// Typically, views will construct Node subclasses which will perform any custom layout and drawing logic.
    ///
    /// - Parameters:
    ///   - node: node representing parent in hierarchy
    @MainActor func build(parent: Node?) -> Node

    /// Update the Node hierarchy based on the current contents of the view.
    ///
    /// - Parameters:
    /// - node: the node in the view hierachy which will be updated based on this view.
    @MainActor func update(node: Node)

    static var size: Int? { get }
}

extension GenericView {
    static var size: Int? { nil }
}
