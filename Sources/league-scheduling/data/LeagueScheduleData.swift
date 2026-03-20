
import OrderedCollections
import StaticDateTimes

// MARK: Data
/// Fundamental building block that keeps track of and enforces assignment rules when building the schedule.
struct LeagueScheduleData<Config: ScheduleConfiguration>: Sendable, ~Copyable {
    let clock = ContinuousClock()
    var rng:Config.RNG
    let entriesPerMatchup:EntriesPerMatchup
    let entriesCount:Int
    let entryDivisions:ContiguousArray<Division.IDValue>

    var expectedMatchupsCount:Int = 0

    var divisionRecurringDayLimitInterval:ContiguousArray<RecurringDayLimitInterval>

    /// Day index that is currently being scheduled.
    private(set) var day:DayIndex

    /// Number of locations currently available.
    //private(set) var locations:LocationIndex

    /// Maximum number of times a single team can play on `day`.
    private(set) var defaultMaxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay
    private(set) var gameGap:GameGap.TupleValue
    private(set) var sameLocationIfB2B:Bool

    /// - Usage: [`combination index`: [`Division.IDValue`: [`combination`]]]
    var allowedDivisionCombinations:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = []

    /// - Usage: [`selection index` : `Set<previous failed scheduling attempt when selecting any of these matchup pairs>`]
    var failedMatchupSelections:ContiguousArray<Set<MatchupPair>>

    var assignmentState:AssignmentState<Config>
    var prioritizeEarlierTimes:Bool

    var executionSteps = [ExecutionStep]()
    var shuffleHistory = [LeagueShuffleAction]()

    var redistributionData:RedistributionData<Config>?
    var redistributedMatchups = false

    init(
        snapshot: LeagueScheduleDataSnapshot<Config>
    ) {
        //locations = snapshot.locations
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
        assignmentState = snapshot.assignmentState.noncopyable()
        prioritizeEarlierTimes = snapshot.prioritizeEarlierTimes
        executionSteps = snapshot.executionSteps
        shuffleHistory = snapshot.shuffleHistory
    }
}

// MARK: Snapshot
extension LeagueScheduleData {
    mutating func loadSnapshot(_ snapshot: LeagueScheduleDataSnapshot<Config>) {
        //locations = snapshot.locations
        rng = snapshot.rng
        divisionRecurringDayLimitInterval = snapshot.divisionRecurringDayLimitInterval
        day = snapshot.day
        defaultMaxEntryMatchupsPerGameDay = snapshot.defaultMaxEntryMatchupsPerGameDay
        gameGap = snapshot.gameGap
        sameLocationIfB2B = snapshot.sameLocationIfB2B
        allowedDivisionCombinations = snapshot.allowedDivisionCombinations
        failedMatchupSelections = snapshot.failedMatchupSelections
        assignmentState = snapshot.assignmentState.noncopyable()
        prioritizeEarlierTimes = snapshot.prioritizeEarlierTimes
        executionSteps = snapshot.executionSteps
        shuffleHistory = snapshot.shuffleHistory
    }

    func snapshot() -> LeagueScheduleDataSnapshot<Config> {
        return .init(self)
    }
}

// MARK: New Day
extension LeagueScheduleData {
    /// Indicates a new day will begin to be scheduled.
    /// 
    /// - Parameters:
    ///   - day: Day index that will be scheduled.
    ///   - divisionEntries: Division entries that play on the `day`. (`Division.IDValue`: `Set<Entry.IDValue>`)
    ///   - entryMatchupsPerGameDay: Number of times a single team will play on `day`.
    mutating func newDay(
        day: DayIndex,
        daySettings: GeneralSettings.Runtime,
        divisionEntries: ContiguousArray<Config.DeterministicEntryIDSet>,
        availableSlots: Config.DeterministicAvailableSlotSet,
        settings: RequestPayload.Runtime,
        generationData: inout LeagueGenerationData
    ) throws(LeagueError) {
        let now = clock.now
        assignmentState.startingTimes = daySettings.startingTimes
        assignmentState.matchupDuration = daySettings.matchupDuration
        assignmentState.locationTravelDurations = daySettings.locationTravelDurations ?? .init(repeating: .init(repeating: 0, count: daySettings.locations), count: daySettings.locations)
        divisionRecurringDayLimitInterval = .init(repeating: 0, count: divisionEntries.count)
        self.day = day
        self.defaultMaxEntryMatchupsPerGameDay = daySettings.defaultMaxEntryMatchupsPerGameDay
        self.prioritizeEarlierTimes = daySettings.prioritizeEarlierTimes
        self.gameGap = daySettings.gameGap.minMax
        self.sameLocationIfB2B = daySettings.sameLocationIfB2B
        var availableMatchups = Config.DeterministicMatchupPairSet()
        var prioritizedEntries = Config.DeterministicEntryIDSet()
        prioritizedEntries.reserveCapacity(entriesCount)
        var entryCountsForDivision:ContiguousArray<Int> = .init(repeating: 0, count: divisionEntries.count)
        expectedMatchupsCount = 0
        assignmentState.allDivisionMatchups = .init(repeating: .init(), count: divisionEntries.count)
        for (divisionIndex, var entriesInDivision) in divisionEntries.enumerated() {
            if !entriesInDivision.isEmpty {
                divisionRecurringDayLimitInterval[divisionIndex] = Self.recurringDayLimitInterval(
                    entries: entriesInDivision.count,
                    entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay
                )

                entriesInDivision.forEach { entryID in
                    if assignmentState.numberOfAssignedMatchups[unchecked: entryID] >= daySettings.maximumPlayableMatchups[unchecked: entryID] {
                        entriesInDivision.removeMember(entryID)
                    }
                }

                entryCountsForDivision[divisionIndex] = entriesInDivision.count
                expectedMatchupsCount += (entriesInDivision.count * defaultMaxEntryMatchupsPerGameDay) / entriesPerMatchup
                prioritizedEntries.formUnion(entriesInDivision)
                #if LOG
                print("LeagueScheduleData;newDay;day=\(day);expectedMatchupsCount=\(expectedMatchupsCount);divisionIndex=\(divisionIndex);entryCountsForDivision=\(entriesInDivision.count);divisionRecurringDayLimitInterval=\(divisionRecurringDayLimitInterval[divisionIndex])")
                #endif
                let availableDivisionMatchups:Config.DeterministicMatchupPairSet = entriesInDivision.availableMatchupPairs(
                    assignedEntryHomeAways: assignmentState.assignedEntryHomeAways,
                    maxSameOpponentMatchups: assignmentState.maxSameOpponentMatchups
                )
                self.assignmentState.allDivisionMatchups[divisionIndex] = availableDivisionMatchups
                availableMatchups.formUnion(availableDivisionMatchups)
            }
        }
        expectedMatchupsCount = min(availableSlots.count, expectedMatchupsCount)
        assignmentState.availableSlots = availableSlots
        switch daySettings.gameGap {
        case .no:
            allowedDivisionCombinations = calculateAllowedDivisionMatchupCombinations(
                entriesPerMatchup: entriesPerMatchup,
                locations: daySettings.locations,
                entryCountsForDivision: entryCountsForDivision
            )
        default:
            break
        }
        failedMatchupSelections = .init(repeating: Set(), count: expectedMatchupsCount)
        assignmentState.allMatchups = availableMatchups
        assignmentState.availableMatchups = availableMatchups
        assignmentState.prioritizedEntries = prioritizedEntries
        assignmentState.matchups = OrderedSet(minimumCapacity: availableSlots.count)
        for i in 0..<assignmentState.playsAt.count {
            assignmentState.playsAt[unchecked: i].removeAllKeepingCapacity()
        }
        assignmentState.playsAtTimes.removeAllKeepingCapacity()
        for i in 0..<assignmentState.playsAtLocations.count {
            assignmentState.playsAtLocations[unchecked: i].removeAll(keepingCapacity: true)
        }
        assignmentState.recalculateNewDayRemainingAllocations(entriesCount: entriesCount)

        #if LOG
        print("newDay;day=\(day);availableSlots=\(availableSlots.map({ $0.description }));defaultMaxEntryMatchupsPerGameDay=\(defaultMaxEntryMatchupsPerGameDay);expectedMatchupsCount=\(expectedMatchupsCount);availableMatchups.count=\(availableMatchups.count);allowedDivisionCombinations=\(allowedDivisionCombinations);numberOfAssignedMatchups=\(assignmentState.numberOfAssignedMatchups);maximumPlayableMatchups=\(assignmentState.maximumPlayableMatchups)")
        #endif

        redistributedMatchups = false

        let elapsedDuration = clock.now - now
        executionSteps.append(.init(key: "newDay (\(day))", duration: elapsedDuration))

        if expectedMatchupsCount <= 0 {
            if daySettings.redistributionSettings != nil {
                try tryRedistributing(
                    settings: settings,
                    generationData: &generationData
                )
            } else {
                throw .failedZeroExpectedMatchupsForDay(day)
            }
        }
    }
}

// MARK: Get recurring day limit interval
extension LeagueScheduleData {
    static func recurringDayLimitInterval(
        entries: Int,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay
    ) -> RecurringDayLimitInterval {
        return RecurringDayLimitInterval(EntryMatchupsPerGameDay(entries - 1) / entryMatchupsPerGameDay)
    }
}