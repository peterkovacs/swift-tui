
public struct EmptyView: View, PrimitiveView {
    public init() {}
    
    func build(parent: Node?, root: RootNode?) -> Node {
        return Node(view: self, parent: parent, root: root)
    }
    func update(node: Node) {}
}
