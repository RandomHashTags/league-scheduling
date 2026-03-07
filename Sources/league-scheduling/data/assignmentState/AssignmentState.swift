
import StaticDateTimes

// MARK: Noncopyable
struct AssignmentState<Config: ScheduleConfiguration>: Sendable, ~Copyable {
    let entries:[Config.EntryRuntime]
    var startingTimes:[StaticTime]
    var matchupDuration:LeagueMatchupDuration
    var locationTravelDurations:[[LeagueMatchupDuration]]

    /// - Usage: [`LeagueEntry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]

    /// Remaining allocations allowed for a matchup pair, for a `LeagueDayIndex`.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: `the number of remaining allocations`]
    var remainingAllocations:RemainingAllocations

    /// When entries can play against each other again.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: `LeagueRecurringDayLimitInterval`]]
    var recurringDayLimits:RecurringDayLimits

    var assignedTimes:LeagueAssignedTimes
    var assignedLocations:LeagueAssignedLocations
    let maximumPlayableMatchups:[UInt32]
    let maxTimeAllocations:MaximumTimeAllocations
    let maxLocationAllocations:MaximumLocationAllocations

    /// Number of times an entry was assigned to play at home or away against another entry.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: [`home (0) or away (1)`: `total played`]]]
    var assignedEntryHomeAways:AssignedEntryHomeAways

    /// Total number of 'home' matchups an entry has played.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: `number of matchups played at 'home'`]
    var homeMatchups:[UInt8]

    /// Total number of 'away' matchups an entry has played.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: `number of matchups played at 'away'`]
    var awayMatchups:[UInt8]

    let maxSameOpponentMatchups:LeagueMaximumSameOpponentMatchups

    /// All matchup pairs that can be scheduled.
    var allMatchups:Set<LeagueMatchupPair>

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`LeagueDivision.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Set<LeagueMatchupPair>>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Set<LeagueMatchupPair>

    var prioritizedEntries:Set<LeagueEntry.IDValue>

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Set<LeagueAvailableSlot>
    
    var playsAt:PlaysAt
    var playsAtTimes:ContiguousArray<Config.TimeSet>
    var playsAtLocations:ContiguousArray<Config.LocationSet>

    /// Available matchups that can be scheduled.
    var matchups:Set<LeagueMatchup>

    var shuffleHistory = [LeagueShuffleAction]()

    func copyable() -> AssignmentStateCopyable<Config> {
        return .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            remainingAllocations: remainingAllocations,
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
            remainingAllocations: remainingAllocations,
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
    let matchupDuration:LeagueMatchupDuration
    let locationTravelDurations:[[LeagueMatchupDuration]]

    /// - Usage: [`LeagueEntry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]
    var remainingAllocations:RemainingAllocations
    var recurringDayLimits:RecurringDayLimits
    var assignedTimes:LeagueAssignedTimes
    var assignedLocations:LeagueAssignedLocations
    var maximumPlayableMatchups:[UInt32]
    var maxTimeAllocations:MaximumTimeAllocations
    var maxLocationAllocations:MaximumLocationAllocations

    var assignedEntryHomeAways:AssignedEntryHomeAways

    /// Total number of 'home' matchups an entry has played.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: `# of matchups played at 'home'`]
    var homeMatchups:[UInt8]

    /// Total number of 'away' matchups an entry has played.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: `# of matchups played at 'away'`]
    var awayMatchups:[UInt8]

    var maxSameOpponentMatchups:LeagueMaximumSameOpponentMatchups

    /// All matchup pairs that can be scheduled
    var allMatchups:Set<LeagueMatchupPair>

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`LeagueDivision.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Set<LeagueMatchupPair>>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Set<LeagueMatchupPair>

    var prioritizedEntries:Set<LeagueEntry.IDValue>

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Set<LeagueAvailableSlot>

    var playsAt:PlaysAt
    var playsAtTimes:ContiguousArray<Config.TimeSet>
    var playsAtLocations:ContiguousArray<Config.LocationSet>
    var matchups:Set<LeagueMatchup>

    var shuffleHistory:[LeagueShuffleAction]

    func noncopyable() -> AssignmentState<Config> {
        return .init(
            entries: entries,
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            locationTravelDurations: locationTravelDurations,
            numberOfAssignedMatchups: numberOfAssignedMatchups,
            remainingAllocations: remainingAllocations,
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