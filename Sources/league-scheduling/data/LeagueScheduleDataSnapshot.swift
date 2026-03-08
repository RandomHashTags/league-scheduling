
import StaticDateTimes

struct LeagueScheduleDataSnapshot<Config: ScheduleConfiguration>: Sendable {
    let entriesPerMatchup:LeagueEntriesPerMatchup
    let entriesCount:Int
    let entryDivisions:ContiguousArray<LeagueDivision.IDValue>

    var divisionRecurringDayLimitInterval:ContiguousArray<LeagueRecurringDayLimitInterval> = []

    /// Day index that is currently being scheduled.
    private(set) var day:LeagueDayIndex = 0

    /// Maximum number of times a single team can play on `day`.
    private(set) var defaultMaxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 0
    private(set) var gameGap:GameGap.TupleValue
    private(set) var sameLocationIfB2B:Bool

    var allowedDivisionCombinations:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = []

    /// - Usage: [`selection index` : `Set<previous failed scheduling attempt when selecting any of these matchup pairs>`]
    var failedMatchupSelections:ContiguousArray<Set<LeagueMatchupPair>>

    var assignmentState:AssignmentStateCopyable<Config>
    var prioritizeEarlierTimes = false

    var executionSteps = [ExecutionStep]()
    var shuffleHistory = [LeagueShuffleAction]()

    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>, BitSet64<LeagueEntry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>, BitSet64<LeagueEntry.IDValue>>)
    init(
        maxStartingTimes: LeagueTimeIndex,
        startingTimes: [StaticTime],
        maxLocations: LeagueLocationIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        maximumPlayableMatchups: [UInt32],
        entries: [Config.EntryRuntime],
        divisionEntries: ContiguousArray<Config.EntryIDSet>,
        matchupDuration: LeagueMatchupDuration,
        gameGap: (Int, Int),
        sameLocationIfB2B: Bool,
        locationTravelDurations: [[LeagueMatchupDuration]],
        maxSameOpponentMatchups: LeagueMaximumSameOpponentMatchups
    ) {
        self.entriesPerMatchup = entriesPerMatchup
        self.entriesCount = entries.count
        self.gameGap = gameGap
        self.sameLocationIfB2B = sameLocationIfB2B

        var prioritizedEntries = Config.EntryIDSet()
        prioritizedEntries.reserveCapacity(entriesCount)
        var entryDivisions = ContiguousArray<LeagueDivision.IDValue>(repeating: 0, count: entriesCount)
        for (index, entries) in divisionEntries.enumerated() {
            prioritizedEntries.formUnion(entries)
            entries.forEach { entry in
                entryDivisions[unchecked: entry] = LeagueDivision.IDValue(index)
            }
        }
        self.entryDivisions = entryDivisions

        failedMatchupSelections = .init(repeating: Set(), count: entriesCount)
        assignmentState = .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: .init(repeating: 0, count: entriesCount),
            remainingAllocations: [],
            recurringDayLimits: .init(repeating: .init(repeating: 0, count: entriesCount), count: entriesCount),
            assignedTimes: .init(repeating: .init(repeating: 0, count: maxStartingTimes), count: entriesCount),
            assignedLocations: .init(repeating: .init(repeating: 0, count: maxLocations), count: entriesCount),
            maximumPlayableMatchups: maximumPlayableMatchups,
            maxTimeAllocations: .init(repeating: .init(repeating: 0, count: maxStartingTimes), count: entriesCount),
            maxLocationAllocations: .init(repeating: .init(repeating: 0, count: maxLocations), count: entriesCount),
            assignedEntryHomeAways: .init(repeating: .init(repeating: .init(home: 0, away: 0), count: entriesCount), count: entriesCount),
            homeMatchups: .init(repeating: 0, count: entriesCount),
            awayMatchups: .init(repeating: 0, count: entriesCount),
            maxSameOpponentMatchups: maxSameOpponentMatchups,
            allMatchups: [],
            allDivisionMatchups: [],
            availableMatchups: [],
            prioritizedEntries: prioritizedEntries,
            availableSlots: [],
            playsAt: .init(repeating: Set(minimumCapacity: defaultMaxEntryMatchupsPerGameDay), count: entriesCount),
            playsAtTimes: .init(repeating: .init(), count: entriesCount),
            playsAtLocations: .init(repeating: .init(), count: entriesCount),
            matchups: [],
            shuffleHistory: []
        )
    }

    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>, BitSet64<LeagueEntry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>, BitSet64<LeagueEntry.IDValue>>)
    init(_ snapshot: borrowing LeagueScheduleData<Config>) {
        entriesPerMatchup = snapshot.entriesPerMatchup
        entriesCount = snapshot.entriesCount
        entryDivisions = snapshot.entryDivisions
        divisionRecurringDayLimitInterval = snapshot.divisionRecurringDayLimitInterval
        day = snapshot.day
        defaultMaxEntryMatchupsPerGameDay = snapshot.defaultMaxEntryMatchupsPerGameDay
        gameGap = snapshot.gameGap
        sameLocationIfB2B = snapshot.sameLocationIfB2B
        allowedDivisionCombinations = snapshot.allowedDivisionCombinations
        failedMatchupSelections = snapshot.failedMatchupSelections
        assignmentState = snapshot.assignmentState.copyable()
        prioritizeEarlierTimes = snapshot.prioritizeEarlierTimes
        executionSteps = snapshot.executionSteps
        shuffleHistory = snapshot.shuffleHistory
    }
}