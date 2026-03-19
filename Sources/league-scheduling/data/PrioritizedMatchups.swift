
import OrderedCollections

struct PrioritizedMatchups: Sendable, ~Copyable {
    private(set) var matchups:OrderedSet<MatchupPair>
    private(set) var availableMatchupCountForEntry:ContiguousArray<Int>

    init(
        entriesCount: Int,
        prioritizedEntries: OrderedSet<Entry.IDValue>,
        availableMatchups: OrderedSet<MatchupPair>
    ) {
        let matchups = Self.filterMatchups(prioritizedEntries: prioritizedEntries, availableMatchups: availableMatchups)
        var availableMatchupCountForEntry = ContiguousArray<Int>(repeating: 0, count: entriesCount)
        for matchup in matchups {
            availableMatchupCountForEntry[unchecked: matchup.team1] += 1
            availableMatchupCountForEntry[unchecked: matchup.team2] += 1
        }
        self.matchups = matchups
        self.availableMatchupCountForEntry = availableMatchupCountForEntry
    }

    mutating func update(
        prioritizedEntries: OrderedSet<Entry.IDValue>,
        availableMatchups: OrderedSet<MatchupPair>
    ) {
        matchups = Self.filterMatchups(prioritizedEntries: prioritizedEntries, availableMatchups: availableMatchups)
        for i in availableMatchupCountForEntry.indices {
            availableMatchupCountForEntry[unchecked: i] = 0
        }
        for matchup in matchups {
            availableMatchupCountForEntry[unchecked: matchup.team1] += 1
            availableMatchupCountForEntry[unchecked: matchup.team2] += 1
        }
    }

    /// Removes the specified matchup pair from `matchups`.
    mutating func remove(_ matchup: MatchupPair) {
        matchups.remove(matchup)
    }

    private static func filterMatchups(
        prioritizedEntries: OrderedSet<Entry.IDValue>,
        availableMatchups: OrderedSet<MatchupPair>
    ) -> OrderedSet<MatchupPair> {
        if prioritizedEntries.isEmpty {
            return availableMatchups
        }
        var matchups = availableMatchups.filter {
            prioritizedEntries.contains($0.team1) && prioritizedEntries.contains($0.team2)
        }
        if matchups.isEmpty { // odd number of entries
            matchups = availableMatchups.filter {
                prioritizedEntries.contains($0.team1) || prioritizedEntries.contains($0.team2)
            }
        }
        return matchups
    }
}