
protocol AbstractSet: Sendable, ~Copyable {
    associatedtype Element:Sendable

    init()
    init(_ collection: some Collection<Element>)

    var count: Int { get }
    var isEmpty: Bool { get }

    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    func contains(_ member: Element) -> Bool

    mutating func reserveCapacity(_ minimumCapacity: Int)

    /// Inserts the given element in the set if it is not already present.
    mutating func insertMember(_ member: Element)

    /// Removes the specified element from the set.
    mutating func removeMember(_ member: Element)

    mutating func removeAll()
    mutating func removeAllKeepingCapacity()
    mutating func removeAll(where condition: (Element) throws -> Bool) rethrows

    mutating func formUnion(_ other: borrowing Self)

    func randomElement() -> Element?

    func forEach(_ body: (Element) throws -> Void) rethrows
    func forEachWithReturn<Result>(_ body: (Element) throws -> Result?) rethrows -> Result?
}

protocol SetOfDayIndexes: AbstractSet, ~Copyable where Element == DayIndex {}
protocol SetOfTimeIndexes: AbstractSet, ~Copyable where Element == TimeIndex {}
protocol SetOfLocationIndexes: AbstractSet, ~Copyable where Element == LocationIndex {}

protocol SetOfEntryIDs: AbstractSet, ~Copyable where Element == Entry.IDValue {
    /// - Returns: The available matchup pairs that can play for the `day`.
    func availableMatchupPairs(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> Set<MatchupPair>
}

extension Set: AbstractSet {
    @inline(__always)
    mutating func removeMember(_ member: Element) {
        self.remove(member)
    }

    @inline(__always)
    mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }
    @inline(__always)
    mutating func removeAllKeepingCapacity() {
        self.removeAll(keepingCapacity: true)
    }

    mutating func removeAll(where condition: (Element) throws -> Bool) rethrows {
        var iterator = makeIterator()
        while let next = iterator.next() {
            if try condition(next) {
                remove(next)
            }
        }
    }

    func forEachWithReturn<Result>(_ body: (Element) throws -> Result?) rethrows -> Result? {
        for e in self {
            if let r = try body(e) {
                return r
            }
        }
        return nil
    }

    @inline(__always)
    mutating func insertMember(_ member: Element) {
        insert(member)
    }
}

extension Set<DayIndex>: SetOfDayIndexes {}
extension Set<TimeIndex>: SetOfTimeIndexes {}
extension Set<LocationIndex>: SetOfLocationIndexes {}

extension Set<Entry.IDValue>: SetOfEntryIDs {
    func availableMatchupPairs(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> Set<MatchupPair> {
        var pairs = Set<MatchupPair>(minimumCapacity: (count-1) * 2)
        let sortedEntries = sorted()
        var index = 0
        while index < sortedEntries.count - 1 {
            let home = sortedEntries[index]
            index += 1
            let assignedHome = assignedEntryHomeAways[unchecked: home]
            let maxSameOpponentMatchups = maxSameOpponentMatchups[unchecked: home]
            for away in sortedEntries[index...] {
                if assignedHome[unchecked: away].sum < maxSameOpponentMatchups[unchecked: away] {
                    pairs.insert(.init(team1: home, team2: away))
                }
            }
        }
        return pairs
    }
}