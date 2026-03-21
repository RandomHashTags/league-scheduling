
import StaticDateTimes

// MARK: Noncopyable
struct AssignmentState<Config: ScheduleConfiguration>: Sendable, ~Copyable {
    let entries:[Config.EntryRuntime]
    var startingTimes:[StaticTime]
    var matchupDuration:MatchupDuration
    var locationTravelDurations:[[MatchupDuration]]

    /// - Usage: [`Entry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]

    /// Remaining allocations allowed for a matchup pair, for a `DayIndex`.
    /// 
    /// - Usage: [`Entry.IDValue`: `the number of remaining allocations`]
    var possibleAllocations:Config.PossibleAllocations

    /// When entries can play against each other again.
    /// 
    /// - Usage: [`Entry.IDValue`: [opponent `Entry.IDValue`: `RecurringDayLimitInterval`]]
    var recurringDayLimits:RecurringDayLimits

    var assignedTimes:AssignedTimes
    var assignedLocations:AssignedLocations
    let maximumPlayableMatchups:[UInt32]
    let maxTimeAllocations:MaximumTimeAllocations
    let maxLocationAllocations:MaximumLocationAllocations

    /// Number of times an entry was assigned to play at home or away against another entry.
    /// 
    /// - Usage: [`Entry.IDValue`: [opponent `Entry.IDValue`: [`home (0) or away (1)`: `total played`]]]
    var assignedEntryHomeAways:AssignedEntryHomeAways

    /// Total number of 'home' matchups an entry has played.
    /// 
    /// - Usage: [`Entry.IDValue`: `number of matchups played at 'home'`]
    var homeMatchups:[UInt8]

    /// Total number of 'away' matchups an entry has played.
    /// 
    /// - Usage: [`Entry.IDValue`: `number of matchups played at 'away'`]
    var awayMatchups:[UInt8]

    let maxSameOpponentMatchups:MaximumSameOpponentMatchups

    /// All matchup pairs that can be scheduled.
    var allMatchups:Config.MatchupPairSet

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`Division.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Config.MatchupPairSet>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Config.MatchupPairSet

    var prioritizedEntries:Config.EntryIDSet

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Config.AvailableSlotSet
    
    var playsAt:Config.PlaysAt
    var playsAtTimes:PlaysAtTimesArray<Config.TimeSet>
    var playsAtLocations:ContiguousArray<Config.LocationSet>

    /// Available matchups that can be scheduled.
    var matchups:Config.MatchupSet

    var shuffleHistory = [LeagueShuffleAction]()

    #if SpecializeScheduleConfiguration
    @_specialize(where Config == ScheduleConfig<BitSet64<DayIndex>, BitSet64<TimeIndex>, BitSet64<LocationIndex>, BitSet64<Entry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<Set<DayIndex>, Set<TimeIndex>, Set<LocationIndex>, Set<Entry.IDValue>>)
    #endif
    func copyable() -> AssignmentStateCopyable<Config> {
        return .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            possibleAllocations: possibleAllocations,
            recurringDayLimits: recurringDayLimits,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            maximumPlayableMatchups: maximumPlayableMatchups,
            maxTimeAllocations: maxTimeAllocations,
            maxLocationAllocations: maxLocationAllocations,
            assignedEntryHomeAways: assignedEntryHomeAways,
            homeMatchups: homeMatchups,
            awayMatchups: awayMatchups,
            maxSameOpponentMatchups: maxSameOpponentMatchups,
            allMatchups: allMatchups,
            allDivisionMatchups: allDivisionMatchups,
            availableMatchups: availableMatchups,
            prioritizedEntries: prioritizedEntries,
            availableSlots: availableSlots,
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            matchups: matchups,
            shuffleHistory: shuffleHistory
        )
    }

    func copy() -> AssignmentState {
        return .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            possibleAllocations: possibleAllocations,
            recurringDayLimits: recurringDayLimits,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            maximumPlayableMatchups: maximumPlayableMatchups,
            maxTimeAllocations: maxTimeAllocations,
            maxLocationAllocations: maxLocationAllocations,
            assignedEntryHomeAways: assignedEntryHomeAways,
            homeMatchups: homeMatchups,
            awayMatchups: awayMatchups,
            maxSameOpponentMatchups: maxSameOpponentMatchups,
            allMatchups: allMatchups,
            allDivisionMatchups: allDivisionMatchups,
            availableMatchups: availableMatchups,
            prioritizedEntries: prioritizedEntries,
            availableSlots: availableSlots,
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            matchups: matchups,
            shuffleHistory: shuffleHistory
        )
    }
}

// MARK: Copyable
struct AssignmentStateCopyable<Config: ScheduleConfiguration> {
    let entries:[Config.EntryRuntime]
    let startingTimes:[StaticTime]
    let matchupDuration:MatchupDuration
    let locationTravelDurations:[[MatchupDuration]]

    /// - Usage: [`Entry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]
    var possibleAllocations:Config.PossibleAllocations
    var recurringDayLimits:RecurringDayLimits
    var assignedTimes:AssignedTimes
    var assignedLocations:AssignedLocations
    var maximumPlayableMatchups:[UInt32]
    var maxTimeAllocations:MaximumTimeAllocations
    var maxLocationAllocations:MaximumLocationAllocations

    var assignedEntryHomeAways:AssignedEntryHomeAways

    /// Total number of 'home' matchups an entry has played.
    /// 
    /// - Usage: [`Entry.IDValue`: `# of matchups played at 'home'`]
    var homeMatchups:[UInt8]

    /// Total number of 'away' matchups an entry has played.
    /// 
    /// - Usage: [`Entry.IDValue`: `# of matchups played at 'away'`]
    var awayMatchups:[UInt8]

    var maxSameOpponentMatchups:MaximumSameOpponentMatchups

    /// All matchup pairs that can be scheduled
    var allMatchups:Config.MatchupPairSet

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`Division.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Config.MatchupPairSet>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Config.MatchupPairSet

    var prioritizedEntries:Config.EntryIDSet

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Config.AvailableSlotSet

    var playsAt:Config.PlaysAt
    var playsAtTimes:PlaysAtTimesArray<Config.TimeSet>
    var playsAtLocations:ContiguousArray<Config.LocationSet>
    var matchups:Config.MatchupSet

    var shuffleHistory:[LeagueShuffleAction]

    #if SpecializeScheduleConfiguration
    @_specialize(where Config == ScheduleConfig<BitSet64<DayIndex>, BitSet64<TimeIndex>, BitSet64<LocationIndex>, BitSet64<Entry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<Set<DayIndex>, Set<TimeIndex>, Set<LocationIndex>, Set<Entry.IDValue>>)
    #endif
    func noncopyable() -> AssignmentState<Config> {
        return .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            possibleAllocations: possibleAllocations,
            recurringDayLimits: recurringDayLimits,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            maximumPlayableMatchups: maximumPlayableMatchups,
            maxTimeAllocations: maxTimeAllocations,
            maxLocationAllocations: maxLocationAllocations,
            assignedEntryHomeAways: assignedEntryHomeAways,
            homeMatchups: homeMatchups,
            awayMatchups: awayMatchups,
            maxSameOpponentMatchups: maxSameOpponentMatchups,
            allMatchups: allMatchups,
            allDivisionMatchups: allDivisionMatchups,
            availableMatchups: availableMatchups,
            prioritizedEntries: prioritizedEntries,
            availableSlots: availableSlots,
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            matchups: matchups,
            shuffleHistory: shuffleHistory
        )
    }
}