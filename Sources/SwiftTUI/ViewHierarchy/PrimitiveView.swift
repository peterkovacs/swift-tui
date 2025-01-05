import Foundation

protocol PrimitiveView: GenericView {}
extension PrimitiveView {
    public var body: Never { fatalError("Cannot evaluate body of primitive view") }
}
