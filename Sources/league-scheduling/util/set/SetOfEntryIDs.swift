
import OrderedCollections

protocol SetOfEntryIDs: AbstractSet, ~Copyable where Element == Entry.IDValue {
    /// - Returns: The available matchup pairs that can play for the `day`.
    func availableMatchupPairs<MatchupPairSet: AbstractSet>(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> MatchupPairSet where MatchupPairSet.Element == MatchupPair
}

extension Set<Entry.IDValue>: SetOfEntryIDs {
    func availableMatchupPairs<MatchupPairSet: AbstractSet>(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> MatchupPairSet where MatchupPairSet.Element == MatchupPair {
        guard !isEmpty else { return .init() } // https://github.com/apple/swift-collections/issues/608
        var pairs = MatchupPairSet()
        pairs.reserveCapacity((count-1) * 2)
        let sortedEntries = sorted()
        var index = 0
        while index < sortedEntries.count - 1 {
            let home = sortedEntries[index]
            index += 1
            let assignedHome = assignedEntryHomeAways[unchecked: home]
            let maxSameOpponentMatchups = maxSameOpponentMatchups[unchecked: home]
            for away in sortedEntries[index...] {
                if assignedHome[unchecked: away].sum < maxSameOpponentMatchups[unchecked: away] {
                    pairs.insertMember(.init(team1: home, team2: away))
                }
            }
        }
        return pairs
    }
}

extension OrderedSet<Entry.IDValue>: SetOfEntryIDs {
    func availableMatchupPairs<MatchupPairSet: AbstractSet>(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> MatchupPairSet where MatchupPairSet.Element == MatchupPair {
        guard !isEmpty else { return .init() } // https://github.com/apple/swift-collections/issues/608
        var pairs = MatchupPairSet()
        pairs.reserveCapacity((count-1) * 2)
        let sortedEntries = sorted()
        var index = 0
        while index < sortedEntries.count - 1 {
            let home = sortedEntries[index]
            index += 1
            let assignedHome = assignedEntryHomeAways[unchecked: home]
            let maxSameOpponentMatchups = maxSameOpponentMatchups[unchecked: home]
            for away in sortedEntries[index...] {
                if assignedHome[unchecked: away].sum < maxSameOpponentMatchups[unchecked: away] {
                    pairs.insertMember(.init(team1: home, team2: away))
                }
            }
        }
        return pairs
    }
}