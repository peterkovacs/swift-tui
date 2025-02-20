import Foundation

@MainActor
@resultBuilder
public struct ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }

    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }

    public static func buildIf<V: View>(_ content: V)  -> V  { content }

    public static func buildOptional<V: View>(_ content: V?) -> OptionalView<V> {
        OptionalView(content: content)
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(first: TrueContent) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(content: .a(first))
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(second: FalseContent) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(content: .b(second))
    }

    static func buildBlock<each Content: View>(_ content: repeat each Content) -> some View {
        TupleView(content: (repeat each content))
    }
}
