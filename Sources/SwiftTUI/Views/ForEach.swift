public struct ForEach<Data, ID, Content>: View, PrimitiveView where Data : RandomAccessCollection, Data.Index: Hashable, ID : Hashable, Content : View {
    public var data: Data
    public var content: (Data.Element) -> Content
    private var id: KeyPath<Data.Element, ID>

    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) where Data.Element: Identifiable, ID == Data.Element.ID {
        self.data = data
        self.content = content
        id = \.id
    }

    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content

    }

    func build(parent: Node?, root: RootNode?) -> Node {
        let node = Node(
            view: self,
            parent: parent,
            root: root
        )

        for i in data {
            let view = content(i)

            node.add(
                at: node.children.endIndex,
                node: view.view.build(parent: node, root: root)
            )
        }

        return node
    }


    func update(node: Node) {
        guard let previous = node.view as? Self else { fatalError() }

        let diffs = data.difference(
            from: previous.data,
            by: { $0[keyPath: id] == $1[keyPath: id] }
        )

        if diffs.isEmpty {
            for (child, element) in zip(node.children, data) {
                child.update(view: content(element).view)
            }

            return
        }

        node.invalidateLayout()
        var indices = Set<Int>()

        for diff in diffs {
            switch diff {
            case .insert(offset: let i, element: let element, _):
                indices.insert(i)
                node.add(at: i, node: content(element).view.build(parent: node, root: node.root))
            case .remove(offset: let i, element: _, _):
                node.remove(at: i)
            }
        }

        for index in node.children.indices where !indices.contains(index) {
            node.children[index].update(view: content(data[data.index(data.startIndex, offsetBy: index)]).view)
        }
    }
}

//extension ForEach where Data.Element: Hashable {
//    func update(node: Node) where Data.Element: Hashable {
//        guard let previous = node.view as? Self else { fatalError() }
//
//        let diffs = data.difference(
//            from: previous.data,
//            by: { $0[keyPath: id] == $1[keyPath: id] }
//        ).inferringMoves()
//
//        for diff in diffs {
//            switch diff {
//            case .insert(offset: let i, element: let element, associatedWith: let removal):
//                if let removal {
//                    node.children[removal].update(view: content(element).view)
//                } else {
//                    node.add(at: i, node: content(element).view.build(parent: node))
//                }
//            case .remove(offset: let i, element: let element, associatedWith: let insertion):
//                if let insertion {
//                    node.children[insertion].update(view: content(element).view)
//                } else {
//                    node.remove(at: i)
//                }
//            }
//        }
//    }
//}
