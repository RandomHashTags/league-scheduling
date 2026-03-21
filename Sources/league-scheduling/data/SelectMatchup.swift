
// MARK: Select matchup
extension LeagueScheduleData {
    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    mutating func selectMatchup(prioritizedMatchups: borrowing PrioritizedMatchups<Config>) -> MatchupPair? {
        return assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups, rng: &rng)
    }
}

extension AssignmentState {
    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    func selectMatchup(
        prioritizedMatchups: borrowing PrioritizedMatchups<Config>,
        rng: inout some RandomNumberGenerator & Sendable
    ) -> MatchupPair? {
        return Self.selectMatchup(
            prioritizedMatchups: prioritizedMatchups,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            recurringDayLimits: recurringDayLimits,
            possibleAllocations: possibleAllocations,
            rng: &rng
        )
    }

    /// - Returns: Matchup pair that should be prioritized to be scheduled due to how many allocations it has remaining.
    static func selectMatchup(
        prioritizedMatchups: borrowing PrioritizedMatchups<Config>,
        numberOfAssignedMatchups: [Int],
        recurringDayLimits: RecurringDayLimits,
        possibleAllocations: Config.PossibleAllocations,
        rng: inout some RandomNumberGenerator & Sendable
    ) -> MatchupPair? {
        #if LOG
        print("SelectMatchup;selectMatchup;prioritizedMatchups.count=\(prioritizedMatchups.matchups.count);availableMatchupCountForEntry=\(prioritizedMatchups.availableMatchupCountForEntry)")
        #endif
        var selected:SelectedMatchup! = nil
        // introduce a pool of matchup pairs of equal priority, and random selection, so that we don't repeat identical assignments when
        // - regenerating a failed day
        // - selecting the last matchup pair out of previous pairs of equal priority
        var pool = Config.MatchupPairSet()
        prioritizedMatchups.matchups.forEach { pair in
            let (pairMinMatchupsPlayedSoFar, pairTotalMatchupsPlayedSoFar) = numberOfMatchupsPlayedSoFar(for: pair, numberOfAssignedMatchups: numberOfAssignedMatchups)
            guard selected != nil else {
                selected = select(
                    pair: pair,
                    minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                    totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                    recurringDayLimit: recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits),
                    possibleAllocations: Self.possibleAllocations(for: pair, possibleAllocations: possibleAllocations),
                    remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                    pool: &pool
                )
                return
            }
            guard pairMinMatchupsPlayedSoFar == selected.minMatchupsPlayedSoFar else {
                if pairMinMatchupsPlayedSoFar < selected.minMatchupsPlayedSoFar {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits),
                        possibleAllocations: Self.possibleAllocations(for: pair, possibleAllocations: possibleAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                return
            }
            guard pairTotalMatchupsPlayedSoFar == selected.totalMatchupsPlayedSoFar else {
                if pairTotalMatchupsPlayedSoFar < selected.totalMatchupsPlayedSoFar {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits),
                        possibleAllocations: Self.possibleAllocations(for: pair, possibleAllocations: possibleAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                return
            }
            let pairRecurringDayLimit = recurringDayLimit(for: pair, recurringDayLimits: recurringDayLimits)
            guard pairRecurringDayLimit == selected.recurringDayLimit else {
                if pairRecurringDayLimit < selected.recurringDayLimit {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        possibleAllocations: Self.possibleAllocations(for: pair, possibleAllocations: possibleAllocations),
                        remainingMatchupCount: remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                return
            }

            let pairRemainingAllocations = Self.possibleAllocations(for: pair, possibleAllocations: possibleAllocations)
            guard pairRemainingAllocations.min == selected.possibleAllocations.min else {
                if pairRemainingAllocations.min < selected.possibleAllocations.min {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        possibleAllocations: pairRemainingAllocations,
                        remainingMatchupCount: Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                return
            }
            guard pairRemainingAllocations.max == selected.possibleAllocations.max else {
                if pairRemainingAllocations.max < selected.possibleAllocations.max {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        possibleAllocations: pairRemainingAllocations,
                        remainingMatchupCount: Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry),
                        pool: &pool
                    )
                }
                return
            }

            let pairRemainingMatchupCount = Self.remainingMatchupCount(for: pair, prioritizedMatchups.availableMatchupCountForEntry)
            guard pairRemainingMatchupCount.min == selected.remainingMatchupCount.min else {
                if pairRemainingMatchupCount.min < selected.remainingMatchupCount.min {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        possibleAllocations: pairRemainingAllocations,
                        remainingMatchupCount: pairRemainingMatchupCount,
                        pool: &pool
                    )
                }
                return
            }
            guard pairRemainingMatchupCount.max == selected.remainingMatchupCount.max else {
                if pairRemainingMatchupCount.max < selected.remainingMatchupCount.max {
                    selected = select(
                        pair: pair,
                        minMatchupsPlayedSoFar: pairMinMatchupsPlayedSoFar,
                        totalMatchupsPlayedSoFar: pairTotalMatchupsPlayedSoFar,
                        recurringDayLimit: pairRecurringDayLimit,
                        possibleAllocations: pairRemainingAllocations,
                        remainingMatchupCount: pairRemainingMatchupCount,
                        pool: &pool
                    )
                }
                return
            }

            pool.insertMember(pair)
        }
        #if LOG
        print("SelectMatchup;selectMatchup;selected.pair=\(selected.pair.description);pool=\(pool.map({ $0.description }))")
        #endif
        return pool.isEmpty ? selected?.pair : pool.randomElement(using: &rng)
    }
}

extension AssignmentState {
    private struct SelectedMatchup: Sendable, ~Copyable {
        var pair:MatchupPair
        /// The minimum number of matchups `pair.team1` or `pair.team2` has played so far
        var minMatchupsPlayedSoFar:Int
        /// The sum of the total number of matchups `pair.team1` and `pair.team2` has played so far
        var totalMatchupsPlayedSoFar:Int
        var possibleAllocations:(min: Int, max: Int)
        var remainingMatchupCount:(min: Int, max: Int)
        var recurringDayLimit:RecurringDayLimitInterval
    }
    private static func numberOfMatchupsPlayedSoFar(for pair: MatchupPair, numberOfAssignedMatchups: [Int]) -> (minimum: Int, total: Int) {
        let t1 = numberOfAssignedMatchups[unchecked: pair.team1]
        let t2 = numberOfAssignedMatchups[unchecked: pair.team2]
        return (min(t1, t2), t1 + t2)
    }
    private static func recurringDayLimit(for pair: MatchupPair, recurringDayLimits: RecurringDayLimits) -> RecurringDayLimitInterval {
        return recurringDayLimits[unchecked: pair.team1][unchecked: pair.team2]
    }
    private static func possibleAllocations(for pair: MatchupPair, possibleAllocations: Config.PossibleAllocations) -> (min: Int, max: Int) {
        let team1 = possibleAllocations[unchecked: pair.team1].count
        let team2 = possibleAllocations[unchecked: pair.team2].count
        return (
            min(team1, team2),
            max(team1, team2)
        )
    }
    private static func remainingMatchupCount(for pair: MatchupPair, _ availableMatchupCountForEntry: ContiguousArray<Int>) -> (min: Int, max: Int) {
        let team1 = availableMatchupCountForEntry[unchecked: pair.team1]
        let team2 = availableMatchupCountForEntry[unchecked: pair.team2]
        return (
            min(team1, team2),
            max(team1, team2)
        )
    }
    private static func select(
        pair: MatchupPair,
        minMatchupsPlayedSoFar: Int,
        totalMatchupsPlayedSoFar: Int,
        recurringDayLimit: RecurringDayLimitInterval,
        possibleAllocations: (min: Int, max: Int),
        remainingMatchupCount: (min: Int, max: Int),
        pool: inout Config.MatchupPairSet
    ) -> SelectedMatchup {
        pool.removeAllKeepingCapacity()
        pool.insertMember(pair)
        return .init(
            pair: pair,
            minMatchupsPlayedSoFar: minMatchupsPlayedSoFar,
            totalMatchupsPlayedSoFar: totalMatchupsPlayedSoFar,
            possibleAllocations: possibleAllocations,
            remainingMatchupCount: remainingMatchupCount,
            recurringDayLimit: recurringDayLimit
        )
    }
}