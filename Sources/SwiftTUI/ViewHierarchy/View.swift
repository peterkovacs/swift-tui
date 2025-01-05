import Foundation

public protocol View: Sendable {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension View {
    var view: any GenericView {
        if let primitiveView = self as? any PrimitiveView {
            return primitiveView
        }

        return ComposedView(view: self)
    }
}

extension Never: View {
    public var body: Never {
        fatalError()
    }

    public typealias Body = Never
}
