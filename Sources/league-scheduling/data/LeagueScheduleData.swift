
import StaticDateTimes

// MARK: Data
/// Fundamental building block that keeps track of and enforces assignment rules when building the schedule.
struct LeagueScheduleData<Config: ScheduleConfiguration>: Sendable, ~Copyable {
    let clock = ContinuousClock()
    let entriesPerMatchup:LeagueEntriesPerMatchup
    let entriesCount:Int
    let entryDivisions:ContiguousArray<LeagueDivision.IDValue>

    var expectedMatchupsCount:Int = 0

    var divisionRecurringDayLimitInterval:ContiguousArray<LeagueRecurringDayLimitInterval>

    /// Day index that is currently being scheduled.
    private(set) var day:LeagueDayIndex

    /// Number of locations currently available.
    //private(set) var locations:LeagueLocationIndex

    /// Maximum number of times a single team can play on `day`.
    private(set) var defaultMaxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay
    private(set) var gameGap:GameGap.TupleValue
    private(set) var sameLocationIfB2B:Bool

    /// - Usage: [`combination index`: [`LeagueDivision.IDValue`: [`combination`]]]
    var allowedDivisionCombinations:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = []

    /// - Usage: [`selection index` : `Set<previous failed scheduling attempt when selecting any of these matchup pairs>`]
    var failedMatchupSelections:ContiguousArray<Set<LeagueMatchupPair>>

    var assignmentState:AssignmentState<Config>
    var prioritizeEarlierTimes:Bool

    var executionSteps = [ExecutionStep]()
    var shuffleHistory = [LeagueShuffleAction]()

    var redistributionData:RedistributionData<Config>?
    var redistributedMatchups = false

    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>)
    init(
        snapshot: LeagueScheduleDataSnapshot<Config>
    ) {
        //locations = snapshot.locations
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
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>)
    mutating func loadSnapshot(_ snapshot: LeagueScheduleDataSnapshot<Config>) {
        //locations = snapshot.locations
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

    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>)
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
    ///   - divisionEntries: Division entries that play on the `day`. (`LeagueDivision.IDValue`: `Set<LeagueEntry.IDValue>`)
    ///   - entryMatchupsPerGameDay: Number of times a single team will play on `day`.
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>)
    mutating func newDay(
        day: LeagueDayIndex,
        daySettings: LeagueGeneralSettings.Runtime<Config>,
        divisionEntries: ContiguousArray<Set<LeagueEntry.IDValue>>,
        availableSlots: Set<LeagueAvailableSlot>,
        settings: borrowing LeagueRequestPayload.Runtime<Config>,
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
        var availableMatchups = Set<LeagueMatchupPair>()
        var prioritizedEntries = Set<LeagueEntry.IDValue>(minimumCapacity: entriesCount)
        var entryCountsForDivision:ContiguousArray<Int> = .init(repeating: 0, count: divisionEntries.count)
        expectedMatchupsCount = 0
        assignmentState.allDivisionMatchups = .init(repeating: [], count: divisionEntries.count)
        for (divisionIndex, var entriesInDivision) in divisionEntries.enumerated() {
            if !entriesInDivision.isEmpty {
                divisionRecurringDayLimitInterval[divisionIndex] = Self.recurringDayLimitInterval(
                    entries: entriesInDivision.count,
                    entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay
                )

                var iterator = entriesInDivision.makeIterator()
                while let entryID = iterator.next() {
                    if assignmentState.numberOfAssignedMatchups[unchecked: entryID] >= daySettings.maximumPlayableMatchups[unchecked: entryID] {
                        entriesInDivision.remove(entryID)
                    }
                }

                entryCountsForDivision[divisionIndex] = entriesInDivision.count
                expectedMatchupsCount += (entriesInDivision.count * defaultMaxEntryMatchupsPerGameDay) / entriesPerMatchup
                prioritizedEntries.formUnion(entriesInDivision)
                #if LOG
                print("LeagueScheduleData;newDay;day=\(day);expectedMatchupsCount=\(expectedMatchupsCount);divisionIndex=\(divisionIndex);entryCountsForDivision=\(entriesInDivision.count);divisionRecurringDayLimitInterval=\(divisionRecurringDayLimitInterval[divisionIndex])")
                #endif
                let availableDivisionMatchups = availableMatchupPairs(for: entriesInDivision)
                self.assignmentState.allDivisionMatchups[divisionIndex] = availableDivisionMatchups
                availableMatchups.formUnion(availableDivisionMatchups)
            }
        }
        expectedMatchupsCount = min(availableSlots.count, expectedMatchupsCount)
        assignmentState.availableSlots = availableSlots
        if daySettings.gameGap == .no {
            allowedDivisionCombinations = allowedDivisionMatchupCombinations(
                entriesPerMatchup: entriesPerMatchup,
                locations: daySettings.locations,
                entryCountsForDivision: entryCountsForDivision
            )
        }
        failedMatchupSelections = .init(repeating: Set(), count: expectedMatchupsCount)
        assignmentState.allMatchups = availableMatchups
        assignmentState.availableMatchups = availableMatchups
        assignmentState.prioritizedEntries = prioritizedEntries
        assignmentState.matchups = Set(minimumCapacity: availableSlots.count)
        for i in 0..<assignmentState.playsAt.count {
            assignmentState.playsAt[unchecked: i].removeAll(keepingCapacity: true)
        }
        for i in 0..<assignmentState.playsAtTimes.count {
            assignmentState.playsAtTimes[unchecked: i].removeAll()
        }
        for i in 0..<assignmentState.playsAtLocations.count {
            assignmentState.playsAtLocations[unchecked: i].removeAll()
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

// MARK: Available matchup pairs
extension LeagueScheduleData {
    /// - Parameters:
    ///   - entries: The entries that play for the `day`.
    /// - Returns: The available matchup pairs that can play for the `day`.
    func availableMatchupPairs(
        for entries: Set<LeagueEntry.IDValue>
    ) -> Set<LeagueMatchupPair> {
        return Self.availableMatchupPairs(
            for: entries,
            assignedEntryHomeAways: assignmentState.assignedEntryHomeAways,
            maxSameOpponentMatchups: assignmentState.maxSameOpponentMatchups
        )
    }

    /// - Parameters:
    ///   - entries: Entries that will participate in matchup scheduling.
    /// - Returns: The available matchup pairs that can play for the `day`.
    static func availableMatchupPairs(
        for entries: Set<LeagueEntry.IDValue>,
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: LeagueMaximumSameOpponentMatchups
    ) -> Set<LeagueMatchupPair> {
        var pairs = Set<LeagueMatchupPair>(minimumCapacity: (entries.count-1) * 2)
        let sortedEntries = entries.sorted()

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

// MARK: Get recurring day limit interval
extension LeagueScheduleData {
    static func recurringDayLimitInterval(
        entries: Int,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay
    ) -> LeagueRecurringDayLimitInterval {
        return LeagueRecurringDayLimitInterval(LeagueEntryMatchupsPerGameDay(entries - 1) / entryMatchupsPerGameDay)
    }
}