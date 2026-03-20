
protocol AbstractArray: Sendable, ~Copyable {
    associatedtype Index
    associatedtype Element:Sendable

    init()

    mutating func reserveCapacity(_ minimumCapacity: Int)
}

extension ContiguousArray: AbstractArray {
}