public extension View {
  /// Define a style for `Divider` component
  /// - Parameter style: choose a style between `.default`, `.doubled`, `.heavy`
  /// - Returns: Divider styled
    func style(_ style: DividerStyle = .default) -> some View {
        environment(\.dividerStyle, style)
    }
}

private struct DividerStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: DividerStyle { .default }
}

extension EnvironmentValues {
  /// This is used by views like `Divider`, the appearance of which depends
  /// on the orientation of the stack they are in.
  var dividerStyle: DividerStyle {
    get { self[DividerStyleEnvironmentKey.self] }
    set { self[DividerStyleEnvironmentKey.self] = newValue }
  }
}

public struct DividerStyle: Sendable, Equatable {
    let horizontal: Character
    let vertical: Character

    public init(horizontal: Character, vertical: Character) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    /// Define a single line for Divider
    ///
    /// Vertical
    /// ```
    /// │
    /// ```
    ///
    /// Horizontal
    /// ```
    /// ───────────
    /// ```
    public static var `default`: DividerStyle {
        DividerStyle(
            horizontal: "─",
            vertical: "│"
        )
    }


    /// Define a double line for Divider
    ///
    /// Vertical
    /// ```
    /// ║
    /// ```
    ///
    /// Horizontal
    /// ```
    /// ═══════════
    /// ```
    public static var double: DividerStyle {
        DividerStyle(
            horizontal: "═",
            vertical: "║"
        )
    }

    /// Define a heavy line for Divider
    ///
    /// Vertical
    /// ```
    /// ┃
    /// ```
    ///
    /// Horizontal
    /// ```
    /// ━━━━━━━━━━━
    /// ```
    public static var heavy: DividerStyle {
        DividerStyle(
            horizontal: "━",
            vertical: "┃"
        )
    }
}

public struct Divider: View, PrimitiveView {
    @Environment(\.layoutAxis) private var layoutAxis
    @Environment(\.foregroundColor) private var foregroundColor
    @Environment(\.dividerStyle) private var dividerStyle: DividerStyle

    public init() {
    }

    func build(parent: Node?) -> Node {
        let node = DividerNode(
            view: self,
            parent: parent,
            content: self,
            layoutAxis: _layoutAxis,
            foregroundColor: _foregroundColor,
            dividerStyle: _dividerStyle
        )

        // no children.
        return node
    }

    func update(node: Node) {
        guard let node = node as? DividerNode else {
            fatalError(
                "Type mismatch: expected \(DividerNode.self), got \(type(of: node))"
            )
        }

        node.set(references: self)
        node.layoutAxis = layoutAxis
        node.foregroundColor = foregroundColor
        node.dividerStyle = dividerStyle
    }
}

class DividerNode: ComposedNode, Control {
    var layoutAxis: LayoutAxis
    var foregroundColor: Color
    var dividerStyle: DividerStyle

    init<Content: View>(
        view: any GenericView,
        parent: Node?,
        content: Content,
        layoutAxis: Environment<LayoutAxis>,
        foregroundColor: Environment<Color>,
        dividerStyle: Environment<DividerStyle>
    ) {
        self.layoutAxis = .horizontal
        self.foregroundColor = .default
        self.dividerStyle = .default

        super.init(view: view, parent: parent, content: content)

        self.layoutAxis = layoutAxis.wrappedValue
        self.foregroundColor = foregroundColor.wrappedValue
        self.dividerStyle = dividerStyle.wrappedValue

    }

    func size(proposedSize: Size) -> Size {
        switch layoutAxis {
        case .none:
            return .zero
        case .horizontal:
            return .init(width: 1, height: proposedSize.height)
        case .vertical:
            return .init(width: proposedSize.width, height: 1)
        }
    }

    override func layout(rect: Rect) -> Rect {
        switch layoutAxis {
        case .none:
            super.layout(rect: .zero)
        case .horizontal:
            super.layout(
                rect: .init(
                    position: rect.position,
                    size: .init(width: 1, height: rect.size.height)
                )
            )
        case .vertical:
            super.layout(
                rect: .init(
                    position: rect.position,
                    size: .init(width: rect.size.width, height: 1)
                )
            )
        }
    }

    override func size<T>(visitor: inout T) where T : Visitor.Size {
        visitor.visit(
            size: .init(node: self) { [weak self] proposedSize in
                self?.size(proposedSize: proposedSize) ?? .zero
            }
        )
    }

    override func layout<T>(visitor: inout T) where T : Visitor.Layout {
        visitor.visit(
            layout: .init(node: self) { [weak self] rect in
                guard let self else { return .zero }
                return self.layout(rect: rect)
            } frame: { [weak self] rect in
                self?.frame = rect
                return rect
            } global: { [weak self] in
                self?.global ?? .zero
            }
        )
    }

    override func draw(rect: Rect, into window: inout Window<Cell?>) {
        guard let rect = rect.intersection(global) else { return }
        switch layoutAxis {
        case .none: break
        case .horizontal:
            for i in rect.indices {
                window.write(at: i, default: .init(char: dividerStyle.vertical)) {
                    $0.char = dividerStyle.vertical
                    $0.foregroundColor = foregroundColor
                }
            }
        case .vertical:
            for i in rect.indices {
                window.write(at: i, default: .init(char: dividerStyle.vertical)) {
                    $0.char = dividerStyle.horizontal
                    $0.foregroundColor = foregroundColor
                }
            }
        }
    }
}
