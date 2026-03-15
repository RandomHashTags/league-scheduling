
import StaticDateTimes

// MARK: Noncopyable
struct AssignmentState: Sendable, ~Copyable {
    let entries:[Entry.Runtime]
    var startingTimes:[StaticTime]
    var matchupDuration:MatchupDuration
    var locationTravelDurations:[[MatchupDuration]]

    /// - Usage: [`Entry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]

    /// Remaining allocations allowed for a matchup pair, for a `DayIndex`.
    /// 
    /// - Usage: [`Entry.IDValue`: `the number of remaining allocations`]
    var remainingAllocations:RemainingAllocations

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
    var allMatchups:Set<MatchupPair>

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`Division.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Set<MatchupPair>>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Set<MatchupPair>

    var prioritizedEntries:Set<Entry.IDValue>

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Set<AvailableSlot>
    
    var playsAt:PlaysAt
    var playsAtTimes:PlaysAtTimes
    var playsAtLocations:PlaysAtLocations

    /// Available matchups that can be scheduled.
    var matchups:Set<Matchup>

    var shuffleHistory = [LeagueShuffleAction]()

    func copyable() -> AssignmentStateCopyable {
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
struct AssignmentStateCopyable {
    let entries:[Entry.Runtime]
    let startingTimes:[StaticTime]
    let matchupDuration:MatchupDuration
    let locationTravelDurations:[[MatchupDuration]]

    /// - Usage: [`Entry.IDValue`: `total number of matchups played so far in the schedule`]
    var numberOfAssignedMatchups:[Int]
    var remainingAllocations:RemainingAllocations
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
    var allMatchups:Set<MatchupPair>

    /// All matchup pairs that can be scheduled, grouped by division.
    /// 
    /// - Usage: [`Division.IDValue`: `available matchups`]
    var allDivisionMatchups:ContiguousArray<Set<MatchupPair>>

    /// Remaining available matchup pairs that can be assigned for the `day`.
    var availableMatchups:Set<MatchupPair>

    var prioritizedEntries:Set<Entry.IDValue>

    /// Remaining available slots that can be filled for the `day`.
    var availableSlots:Set<AvailableSlot>

    var playsAt:PlaysAt
    var playsAtTimes:PlaysAtTimes
    var playsAtLocations:PlaysAtLocations
    var matchups:Set<Matchup>

    var shuffleHistory:[LeagueShuffleAction]

    func noncopyable() -> AssignmentState {
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