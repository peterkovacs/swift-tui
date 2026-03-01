
/// A node in the view hierarchy responsible for managing view state, layout, drawing, and event propagation.
///
/// Node is the fundamental building block of the framework’s retained rendering tree. Each instance wraps a
/// view-conforming type (via `GenericView`) and maintains parent/child relationships to form a hierarchy that:
/// - Computes intrinsic and container-driven sizes
/// - Performs layout in local and global coordinate spaces
/// - Draws into a backing buffer/window
/// - Propagates focus and input events (keyboard) upwards (bubble) or downwards (hit-testing)
/// - Tracks and invalidates regions for efficient incremental redraw
///
/// Threading:
/// - Constrained to the main actor. All mutations and reads are expected on the main thread.
///
/// Key responsibilities:
/// - View lifecycle: `update(view:)` to reconcile view changes without rebuilding the entire subtree.
/// - Hierarchy management: `add(at:node:)` and `remove(at:)` to modify the tree while preserving invariants.
/// - Layout & drawing: `size(visitor:)`, `layout(visitor:)`, and `draw` methods to perform measurement, placement, and rendering.
/// - Invalidation: `invalidate()` and `invalidateLayout()` to schedule region-based redraws and layout recomputation.
/// - Coordinate systems: `frame` (local to parent), `global` (cached global frame), and `relative(to:)`.
/// - Input handling: `bubble(key:)` to propagate key events to focusable ancestors and `hitTest(at:key:)` to discover controls.
///
/// Extensions:
/// - Debug utilities: `treeDescription` and `frameDescription` provide textual dumps of the hierarchy and frames.
///
/// Performance considerations:
/// - Global frame caching: `global` is memoized and invalidated when `frame` changes.
/// - Region invalidation: `InvalidationVisitor` unions child global frames to minimize redraw areas.
/// - Buffered drawing: `_buffer` caches a window of cells; reset on invalidation.
///
/// Environment:
/// - `environment` is an optional mutator for `EnvironmentValues` applied at this node boundary, allowing scoped
///   environment propagation through the subtree.
///
/// Usage notes:
/// - Subclasses representing concrete controls typically override `size`, `layout`, `draw`, and event handling to
///   implement custom behavior while relying on Node’s traversal mechanisms.
/// - Always call `invalidate()` after changes that affect rendering, and `invalidateLayout()` after changes that
///   affect measurement or placement.
@MainActor
internal class Node {
    var view: any GenericView
    private(set) var root: RootNode?
    private(set) weak var parent: Node? = nil
    private(set) var children: [Node] = []
    var _buffer: Window<Cell?>? = nil

    /// Manipulation of this EnvironmentValues passing through this level.
    var environment: ((inout EnvironmentValues) -> Void)?

    init<T: View>(root view: T) {
        self.view = view.view
    }

    init(view: any GenericView, parent: Node?, root: RootNode?) {
        self.view = view
        self.parent = parent
        self.root = root
    }


    /// Frame of this node, if it is a control, relative to its containing control frame.
    var frame: Rect = .zero {
        didSet {
            _global = nil
        }
    }

    /// Frame of node, if it is a Control, in global coordinates
    private var _global: Rect?
    var global: Rect {
        guard let _global else {
            let frame = relative(to: root)
            _global = frame
            return frame
        }

        return _global
    }

    struct InvalidationVisitor: Visitor.Layout {
        var frame: Rect

        mutating func visit(layout element: Visitor.LayoutElement) {
            frame = frame.union(element.global())
        }

        init(children: [Node]) {
            frame = .zero

            for child in children {
                child.layout(visitor: &self)
            }
        }
    }

    func invalidate() {
        _buffer = nil

        if children.isEmpty {
            root?.invalidate(node: self)
        } else {
            root?.invalidate(node: self, frame: { InvalidationVisitor(children: $0.children).frame })
        }
    }

    func invalidateLayout() {
        parent?.invalidateLayout()
    }

    func bubble(key: Key) -> Bool {
        if let self = self as? Focusable {
            return self.handle(key: key)
        } else if let parent = parent {
            return parent.bubble(key: key)
        } else {
            return false
        }
    }

    /// Performs a depth-first search to find the deepest control capable of handling a given key at the provided position.
    /// - Parameters:
    ///   - position: The point in global coordinates to test against controls’ frames.
    ///   - key: The input key being dispatched (used to filter controls that can handle this input).
    /// - Returns: The first (deepest) `Control` found that can handle the key at the position, or `nil` if none is found.
    /// - Discussion:
    ///   - Traverses children front-to-back order as stored in `children`.
    ///   - Intended to be overridden by control nodes that manage hit areas differing from their frame or that apply
    ///     custom hit-testing logic.
    ///   - Complements `bubble(key:)`, which routes events up the tree once a target control is determined.
    func hitTest(at position: Position, key: Key) -> (any Control)? {
        for child in children {
            if let control = child.hitTest(at: position, key: key) {
                return control
            }
        }

        return nil
    }

    /// Update this node with a given view.
    func update(view: any GenericView) {
        self._global = nil
        view.update(node: self)
        self.view = view
    }

    /// Add a child Node to the hierarchy.
    func add(at index: [Node].Index, node: Node) {
        children.insert(node, at: index)

        // TODO: Maintain `index` invariant
        // for i in index ..< children.endIndex {
        //     children[i].index = i
        // }
    }

    /// Remove a child node from the hierarchy.
    func remove(at index: [Node].Index) {
        children.remove(at: index).parent = nil

        // TODO: Do we need to maintain the `index` invariant on children? If so, update here.
    }

    /// Finds focusable elements within the hierarchy and calls the visitor.
    func focus<T: Visitor.Focus>(visitor: inout T) {
        for child in children {
            child.focus(visitor: &visitor)
        }
    }

    /// Calculate the size of a node hierarchy by visiting each node. Control nodes should override this method with a method that actually calculates it's size.
    func size<T: Visitor.Size>(visitor: inout T) {
        for child in children {
            child.size(visitor: &visitor)
        }
    }

    /// Performs the layout of a node hierarchy by visiting each node. Control nodes should override this method that actually performs its layout.
    func layout<T: Visitor.Layout>(visitor: inout T) {
        for child in children {
            child.layout(visitor: &visitor)
        }
    }

    func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = global.intersection(rect) else { return }
        for child in children {
            child.draw(rect: rect, into: &window)
        }
    }

    /// Calls the callback with each Control in this node's hierarchy.
    ///
    /// - Parameter rect: The invalidated Rect in which to draw.
    /// - Parameter action: A callback that takes the intersection of the controls frame, the control, and the controls frame.
    ///
    /// This can be overridden by descendant types to provide custom logic for calculating the frame passed to action.
    func draw(rect: Rect, action: (_ invalidated: Rect, _ control: Control, _ frame: Rect) -> Void) {
        guard let rect = global.intersection(rect) else { return }

        if let control = self as? Control {
            action(rect, control, control.global)
        } else {
            for child in children {
                child.draw(rect: rect, action: action)
            }
        }
    }

    var description: String {
        "\(type(of: self.view))"
    }

    func relative(to ancestor: Node?) -> Rect {
        guard let ancestor, ancestor !== self else {
            return frame
        }

        var node = self
        var result = frame

        while let parent = node.parent, ancestor !== parent {
            result.position += parent.frame.position
            node = parent
        }

        result.position += node.frame.position

        return result
    }
}

extension Node {
    private func treeDescription(level: Int) -> String {
        var str = ""
        let indent = Array(repeating: " ", count: level * 2).joined()
        str += "\(indent)→ \(description)"

        for child in children {
            str += "\n"
            str += child.frameDescription(level: level + 1)
        }
        return str
    }

    var treeDescription: String {
        treeDescription(level: 0)
    }

    func frameDescription(level: Int) -> String {
        var str = ""
        let indent = Array(repeating: " ", count: level * 2).joined()
        str += "\(indent)→ \(description)"
        if frame != .zero {
            str += " \(global)"
        }
        for child in children {
            str += "\n"
            str += child.frameDescription(level: level + 1)
        }
        return str
    }

    var frameDescription: String {
        frameDescription(level: 0) + "\n"
    }
}
