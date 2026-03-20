
import OrderedCollections
import StaticDateTimes

struct LeagueScheduleDataSnapshot<Config: ScheduleConfiguration>: Sendable {
    let rng:Config.RNG
    let entriesPerMatchup:EntriesPerMatchup
    let entriesCount:Int
    let entryDivisions:ContiguousArray<Division.IDValue>

    var divisionRecurringDayLimitInterval:ContiguousArray<RecurringDayLimitInterval> = []

    /// Day index that is currently being scheduled.
    private(set) var day:DayIndex = 0

    /// Maximum number of times a single team can play on `day`.
    private(set) var defaultMaxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 0
    private(set) var gameGap:GameGap.TupleValue
    private(set) var sameLocationIfB2B:Bool

    var allowedDivisionCombinations:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = []

    /// - Usage: [`selection index` : `Set<previous failed scheduling attempt when selecting any of these matchup pairs>`]
    var failedMatchupSelections:ContiguousArray<Set<MatchupPair>>

    var assignmentState:AssignmentStateCopyable<Config>
    var prioritizeEarlierTimes = false

    var executionSteps = [ExecutionStep]()
    var shuffleHistory = [LeagueShuffleAction]()

    init(
        rng: Config.RNG,
        maxStartingTimes: TimeIndex,
        startingTimes: [StaticTime],
        maxLocations: LocationIndex,
        entriesPerMatchup: EntriesPerMatchup,
        maximumPlayableMatchups: [UInt32],
        entries: [Entry.Runtime],
        divisionEntries: ContiguousArray<Config.DeterministicEntryIDSet>,
        matchupDuration: MatchupDuration,
        gameGap: (Int, Int),
        sameLocationIfB2B: Bool,
        locationTravelDurations: [[MatchupDuration]],
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) {
        self.rng = rng
        self.entriesPerMatchup = entriesPerMatchup
        self.entriesCount = entries.count
        self.gameGap = gameGap
        self.sameLocationIfB2B = sameLocationIfB2B

        var prioritizedEntries = Config.DeterministicEntryIDSet()
        prioritizedEntries.reserveCapacity(entriesCount)
        var entryDivisions = ContiguousArray<Division.IDValue>(repeating: 0, count: entriesCount)
        for (index, entries) in divisionEntries.enumerated() {
            prioritizedEntries.formUnion(entries)
            entries.forEach { entry in
                entryDivisions[unchecked: entry] = Division.IDValue(index)
            }
        }
        self.entryDivisions = entryDivisions

        failedMatchupSelections = .init(repeating: Set(), count: entriesCount)
        let playsAt = ContiguousArray<Config.DeterministicAvailableSlotSet>(
            repeating: .init(minimumCapacity: Int(defaultMaxEntryMatchupsPerGameDay)), count: entriesCount
        )
        let playsAtTimes = PlaysAtTimesArray<Config.TimeSet>(
            times: .init(repeating: .init(minimumCapacity: Int(defaultMaxEntryMatchupsPerGameDay)), count: entriesCount)
        )
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
            allMatchups: .init(),
            allDivisionMatchups: [],
            availableMatchups: .init(),
            prioritizedEntries: prioritizedEntries,
            availableSlots: .init(),
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: .init(repeating: Set(minimumCapacity: defaultMaxEntryMatchupsPerGameDay), count: entriesCount),
            matchups: [],
            shuffleHistory: []
        )
    }
    
    init(_ snapshot: borrowing LeagueScheduleData<Config>) {
        rng = snapshot.rng
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