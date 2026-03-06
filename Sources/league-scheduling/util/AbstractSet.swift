
public protocol AbstractSet: Sendable, ~Copyable {
    associatedtype Element:Sendable

    init()
    init(_ collection: some Collection<Element>)

    var count: Int { get }
    var isEmpty: Bool { get }

    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    func contains(_ member: Element) -> Bool

    /// Inserts the given element in the set if it is not already present.
    mutating func insertMember(_ member: Element)

    /// Removes the specified element from the set.
    mutating func removeMember(_ member: Element)
}

public protocol SetOfTimeIndexes: AbstractSet, ~Copyable where Element == LeagueTimeIndex {
}
protocol SetOfLocationIndexes: AbstractSet, ~Copyable where Element == LeagueLocationIndex {
}

extension Set: AbstractSet {
    @inline(__always)
    public mutating func removeMember(_ member: Element) {
        self.remove(member)
    }

    @inline(__always)
    public mutating func insertMember(_ member: Element) {
        insert(member)
    }
}