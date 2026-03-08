
struct PrioritizedMatchups<Config: ScheduleConfiguration>: Sendable, ~Copyable {
    private(set) var matchups:Set<LeagueMatchupPair>
    private(set) var availableMatchupCountForEntry:ContiguousArray<Int>

    init(
        entriesCount: Int,
        prioritizedEntries: Config.EntryIDSet,
        availableMatchups: Set<LeagueMatchupPair>
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
        prioritizedEntries: Config.EntryIDSet,
        availableMatchups: Set<LeagueMatchupPair>
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
    mutating func remove(_ matchup: LeagueMatchupPair) {
        matchups.remove(matchup)
    }

    private static func filterMatchups(
        prioritizedEntries: Config.EntryIDSet,
        availableMatchups: Set<LeagueMatchupPair>
    ) -> Set<LeagueMatchupPair> {
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