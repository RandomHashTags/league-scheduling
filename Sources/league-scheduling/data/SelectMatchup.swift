
// MARK: Select matchup
extension LeagueScheduleData {
    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    func selectMatchup(prioritizedMatchups: borrowing PrioritizedMatchups) -> LeagueMatchupPair? {
        return assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups)
    }

    mutating func selectAndAssignMatchupBlock(
        amount: Int,
        division: LeagueDivision.IDValue,
        canPlayAtFunc: CanPlayAtClosure,
        shuffleCanPlayAtFunc: OptimizedTeamCanPlayAtClosure
    ) -> Set<LeagueMatchup>? {
        return Self.assignBlockOfMatchups(
            amount: amount,
            division: division,
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            assignmentState: &assignmentState,
            canPlayAtFunc: canPlayAtFunc,
            shuffleCanPlayAtFunc: shuffleCanPlayAtFunc
        )
    }
}

extension AssignmentState {
    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    func selectMatchup(
        prioritizedMatchups: borrowing PrioritizedMatchups
    ) -> LeagueMatchupPair? {
        return Self.selectMatchup(
            prioritizedMatchups: prioritizedMatchups,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            recurringDayLimits: recurringDayLimits,
            remainingAllocations: remainingAllocations
        )
    }

    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    static func selectMatchup(
        prioritizedMatchups: borrowing PrioritizedMatchups,
        numberOfAssignedMatchups: [Int],
        recurringDayLimits: RecurringDayLimits,
        remainingAllocations: RemainingAllocations
    ) -> LeagueMatchupPair? {
        #if LOG
        print("SelectMatchup;selectMatchup;prioritizedMatchups.count=\(prioritizedMatchups.matchups.count);availableMatchupCountForEntry=\(prioritizedMatchups.availableMatchupCountForEntry)")
        #endif
        guard let first = prioritizedMatchups.matchups.first else { return nil }
        guard prioritizedMatchups.matchups.count > 1 else {
            return first//recurringDayLimit(for: first) <= day ? first : nil
        }
        let firstNumberOfMatchupsPlayedSoFar = numberOfMatchupsPlayedSoFar(for: first, numberOfAssignedMatchups: numberOfAssignedMatchups)
        var selected = SelectedMatchup(
            pair: first,
            minMatchupsPlayedSoFar: firstNumberOfMatchupsPlayedSoFar.minimum,
            totalMatchupsPlayedSoFar: firstNumberOfMatchupsPlayedSoFar.total,
            remainingAllocations: Self.remainingAllocations(for: first, remainingAllocations: remainingAllocations),
            remainingMatchupCount: remainingMatchupCount(for: first, prioritizedMatchups.availableMatchupCountForEntry),
            recurringDayLimit: recurringDayLimit(for: first, recurringDayLimits: recurringDayLimits)
        )
        // introduce a pool of matchup pairs of equal priority, and random selection, so that we don't repeat identical assignments when
        // - regenerating a failed day
        // - selecting the last matchup pair out of previous pairs of equal priority
        var pool = Set<LeagueMatchupPair>()
        for pair in prioritizedMatchups.matchups[prioritizedMatchups.matchups.index(after: prioritizedMatchups.matchups.startIndex)...] {
            let (pairMinMatchupsPlayedSoFar, pairTotalMatchupsPlayedSoFar) = numberOfMatchupsPlayedSoFar(for: pair, numberOfAssignedMatchups: numberOfAssignedMatchups)
            guard pairMinMatchupsPlayedSoFar == selected.minMatchupsPlayedSoFar else {
                if pairMinMatchupsPlayedSoFar < selected.minMatchupsPlayedSoFar {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits),
                        remainingAllocations: Self.remainingAllocations(for: pair, remainingAllocations: remainingAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                continue
            }
            guard pairTotalMatchupsPlayedSoFar == selected.totalMatchupsPlayedSoFar else {
                if pairTotalMatchupsPlayedSoFar < selected.totalMatchupsPlayedSoFar {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits),
                        remainingAllocations: Self.remainingAllocations(for: pair, remainingAllocations: remainingAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                continue
            }
            let pairRecurringDayLimit = recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits)
            guard pairRecurringDayLimit == selected.recurringDayLimit else {
                if pairRecurringDayLimit < selected.recurringDayLimit {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        remainingAllocations: Self.remainingAllocations(for: pair, remainingAllocations: remainingAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                continue
            }

            let pairRemainingAllocations = Self.remainingAllocations(for: pair, remainingAllocations: remainingAllocations)
            guard pairRemainingAllocations.min == selected.remainingAllocations.min else {
                if pairRemainingAllocations.min < selected.remainingAllocations.min {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        remainingAllocations: pairRemainingAllocations,
                        remainingMatchupCount: Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                continue
            }
            guard pairRemainingAllocations.max == selected.remainingAllocations.max else {
                if pairRemainingAllocations.max < selected.remainingAllocations.max {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        remainingAllocations: pairRemainingAllocations,
                        remainingMatchupCount: Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                continue
            }

            let pairRemainingMatchupCount = Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry)
            guard pairRemainingMatchupCount.min == selected.remainingMatchupCount.min else {
                if pairRemainingMatchupCount.min < selected.remainingMatchupCount.min {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        remainingAllocations: pairRemainingAllocations,
                        remainingMatchupCount: pairRemainingMatchupCount,
                        pool: &pool
                    )
                }
                continue
            }
            guard pairRemainingMatchupCount.max == selected.remainingMatchupCount.max else {
                if pairRemainingMatchupCount.max < selected.remainingMatchupCount.max {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        remainingAllocations: pairRemainingAllocations,
                        remainingMatchupCount: pairRemainingMatchupCount,
                        pool: &pool
                    )
                }
                continue
            }

            pool.insert(pair)
        }
        #if LOG
        print("SelectMatchup;selectMatchup;selected.pair=\(selected.pair.description);pool=\(pool.map({ $0.description }))")
        #endif
        return pool.isEmpty ? selected.pair : pool.randomElement()
    }
}

extension AssignmentState {
    private struct SelectedMatchup: Sendable, ~Copyable {
        var pair:LeagueMatchupPair
        /// The minimum number of matchups `pair.team1` or `pair.team2` has played so far
        var minMatchupsPlayedSoFar:Int
        /// The sum of the total number of matchups `pair.team1` and `pair.team2` has played so far
        var totalMatchupsPlayedSoFar:Int
        var remainingAllocations:(min: Int, max: Int)
        var remainingMatchupCount:(min: Int, max: Int)
        var recurringDayLimit:LeagueRecurringDayLimitInterval
    }
    private static func numberOfMatchupsPlayedSoFar(for pair: LeagueMatchupPair, numberOfAssignedMatchups: [Int]) -> (minimum: Int, total: Int) {
        let t1 = numberOfAssignedMatchups[unchecked: pair.team1]
        let t2 = numberOfAssignedMatchups[unchecked: pair.team2]
        return (min(t1, t2), t1 + t2)
    }
    private static func recurringDayLimit(for pair: LeagueMatchupPair, recurringDayLimits: RecurringDayLimits) -> LeagueRecurringDayLimitInterval {
        return recurringDayLimits[unchecked: pair.team1][unchecked: pair.team2]
    }
    private static func remainingAllocations(for pair: LeagueMatchupPair, remainingAllocations: RemainingAllocations) -> (min: Int, max: Int) {
        let team1 = remainingAllocations[unchecked: pair.team1].count
        let team2 = remainingAllocations[unchecked: pair.team2].count
        return (
            min(team1, team2),
            max(team1, team2)
        )
    }
    private static func remainingMatchupCount(for pair: LeagueMatchupPair, _ availableMatchupCountForEntry: ContiguousArray<Int>) -> (min: Int, max: Int) {
        let team1 = availableMatchupCountForEntry[unchecked: pair.team1]
        let team2 = availableMatchupCountForEntry[unchecked: pair.team2]
        return (
            min(team1, team2),
            max(team1, team2)
        )
    }
    private static func select(
        pair: LeagueMatchupPair,
        minMatchupsPlayedSoFar: Int,
        totalMatchupsPlayedSoFar: Int,
        recurringDayLimit: LeagueRecurringDayLimitInterval,
        remainingAllocations: (min: Int, max: Int),
        remainingMatchupCount: (min: Int, max: Int),
        pool: inout Set<LeagueMatchupPair>
    ) -> SelectedMatchup {
        pool.removeAll(keepingCapacity: true)
        pool.insert(pair)
        return .init(
            pair: pair,
            minMatchupsPlayedSoFar: minMatchupsPlayedSoFar,
            totalMatchupsPlayedSoFar: totalMatchupsPlayedSoFar,
            remainingAllocations: remainingAllocations,
            remainingMatchupCount: remainingMatchupCount,
            recurringDayLimit: recurringDayLimit
        )
    }
}