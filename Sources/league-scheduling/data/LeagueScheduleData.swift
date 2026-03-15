
import StaticDateTimes

// MARK: Data
/// Fundamental building block that keeps track of and enforces assignment rules when building the schedule.
struct LeagueScheduleData: Sendable, ~Copyable {
    let clock = ContinuousClock()
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

    var assignmentState:AssignmentState
    var prioritizeEarlierTimes:Bool

    var executionSteps = [ExecutionStep]()
    var shuffleHistory = [LeagueShuffleAction]()

    var redistributionData:RedistributionData?
    var redistributedMatchups = false

    init(
        snapshot: LeagueScheduleDataSnapshot
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
    mutating func loadSnapshot(_ snapshot: LeagueScheduleDataSnapshot) {
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

    func snapshot() -> LeagueScheduleDataSnapshot {
        return .init(self)
    }
}

// MARK: HomeAwayValue
extension LeagueSchedule {
    struct HomeAwayValue: Sendable {
        /// Number of matchups played at 'home'.
        var home:UInt8

        /// Number of matchups played at 'away'.
        var away:UInt8

        var sum: UInt16 {
            UInt16(home) + UInt16(away)
        }
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
        divisionEntries: ContiguousArray<Set<Entry.IDValue>>,
        availableSlots: Set<AvailableSlot>,
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
        var availableMatchups = Set<MatchupPair>()
        var prioritizedEntries = Set<Entry.IDValue>(minimumCapacity: entriesCount)
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
        switch daySettings.gameGap {
        case .no:
            allowedDivisionCombinations = Self.allowedDivisionMatchupCombinations(
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
        assignmentState.matchups = Set(minimumCapacity: availableSlots.count)
        for i in 0..<assignmentState.playsAt.count {
            assignmentState.playsAt[unchecked: i].removeAll(keepingCapacity: true)
        }
        for i in 0..<assignmentState.playsAtTimes.count {
            assignmentState.playsAtTimes[unchecked: i].removeAll(keepingCapacity: true)
        }
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

// MARK: Available matchup pairs
extension LeagueScheduleData {
    /// - Parameters:
    ///   - entries: The entries that play for the `day`.
    /// - Returns: The available matchup pairs that can play for the `day`.
    func availableMatchupPairs(
        for entries: Set<Entry.IDValue>
    ) -> Set<MatchupPair> {
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
        for entries: Set<Entry.IDValue>,
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> Set<MatchupPair> {
        var pairs = Set<MatchupPair>(minimumCapacity: (entries.count-1) * 2)
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
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay
    ) -> RecurringDayLimitInterval {
        return RecurringDayLimitInterval(EntryMatchupsPerGameDay(entries - 1) / entryMatchupsPerGameDay)
    }
}