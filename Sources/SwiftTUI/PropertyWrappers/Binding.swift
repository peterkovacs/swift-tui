@MainActor
@propertyWrapper @dynamicMemberLookup public struct Binding<T> {
    let get: @MainActor () -> T
    let set: @MainActor (T) -> Void

    public init(get: @escaping @MainActor () -> T, set: @escaping @MainActor (T) -> Void) {
        self.get = get
        self.set = set
    }

    public var wrappedValue: T {
        get { get() }
        nonmutating set { set(newValue) }
    }

    public var projectedValue: Binding<T> { self }

    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<T, Subject> & Sendable) -> Binding<Subject> {
        .init { [get] in
            get()[keyPath: keyPath]
        } set: { [get, set] value in
            var valueToSet = get()
            valueToSet[keyPath: keyPath] = value
            set(valueToSet)
        }
    }

}
