
public struct EmptyView: View, PrimitiveView {
    public init() {}
    
    func build(parent: Node?) -> Node {
        return Node(view: self, parent: parent)
    }
    func update(node: Node) {}
}
