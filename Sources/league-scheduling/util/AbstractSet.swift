
protocol AbstractSet: Sendable, ~Copyable {
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

    mutating func removeAll()

    func forEach(_ body: (Element) throws -> Void) rethrows
}

protocol SetOfTimeIndexes: AbstractSet, ~Copyable where Element == LeagueTimeIndex {
}
protocol SetOfLocationIndexes: AbstractSet, ~Copyable where Element == LeagueLocationIndex {
}

extension Set: AbstractSet {
    @inline(__always)
    mutating func removeMember(_ member: Element) {
        self.remove(member)
    }

    mutating func removeAll() {
        self.removeAll(keepingCapacity: true)
    }

    @inline(__always)
    mutating func insertMember(_ member: Element) {
        insert(member)
    }
}

extension Set<LeagueTimeIndex>: SetOfTimeIndexes {}
extension Set<LeagueLocationIndex>: SetOfLocationIndexes {}