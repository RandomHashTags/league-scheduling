
struct EntryAssignmentData: Sendable {
    /// Total number of matchups played so far in the schedule.
    var totalNumberOfMatchupsPlayedSoFar = 0

    /// Total number of matchups played at 'home'.
    var totalNumberOfHomeMatchupsPlayedSoFar:UInt8 = 0

    /// Total number of matchups played at 'away'.
    var totalNumberOfAwayMatchupsPlayedSoFar:UInt8 = 0

    var maximumPlayableMatchups:UInt32

    /// Remaining allocations for the current `day`.
    var remainingAllocations:Set<AvailableSlot>

    /// When entries can play against each other again.
    /// 
    /// - Usage: [opponent `Entry.IDValue`: `RecurringDayLimitInterval`]
    var recurringDayLimits:[RecurringDayLimitInterval]

    var assignedTimes:ContiguousArray<UInt8>
    var assignedLocations:ContiguousArray<UInt8>

    /// Number of times an entry was assigned to play at home or away against another entry.
    /// 
    /// - Usage: [opponent `Entry.IDValue`: [`LeagueSchedule.HomeAwayValue`]]
    var assignedEntryHomeAways:[LeagueSchedule.HomeAwayValue]

    /// Maximum number of times an entry can play against another entry.
    ///
    /// - Usage: [opponent `Entry.IDValue`: `maximum allowed matchups for opponent`]
    var maxSameOpponentMatchups:ContiguousArray<MaximumSameOpponentMatchupsCap>

    var playsAt:Set<AvailableSlot>
    var playsAtTimes:Set<TimeIndex>
    var playsAtLocations:Set<LocationIndex>

    var maxTimeAllocations:[TimeIndex]
    var maxLocationAllocations:[LocationIndex]
}

// MARK: Assign
extension EntryAssignmentData {
    mutating func assignHome(
        to slot: AvailableSlot,
        away: Entry.IDValue,
        recurringDayLimitInterval: RecurringDayLimitInterval
    ) {
        totalNumberOfHomeMatchupsPlayedSoFar += 1
        assignedEntryHomeAways[unchecked: away].home += 1
        recurringDayLimits[unchecked: away] += recurringDayLimitInterval
        assign(
            to: slot
        )
    }

    mutating func assignAway(
        to slot: AvailableSlot,
        home: Entry.IDValue,
        recurringDayLimitInterval: RecurringDayLimitInterval
    ) {
        totalNumberOfAwayMatchupsPlayedSoFar += 1
        assignedEntryHomeAways[unchecked: home].away += 1
        recurringDayLimits[unchecked: home] += recurringDayLimitInterval
        assign(
            to: slot
        )
    }

    private mutating func assign(
        to slot: AvailableSlot
    ) {
        totalNumberOfMatchupsPlayedSoFar += 1
        assignedTimes[unchecked: slot.time] += 1
        assignedLocations[unchecked: slot.location] += 1
        playsAt.insert(slot)
        playsAtTimes.insert(slot.time)
        playsAtLocations.insert(slot.location)
    }
}

// MARK: Reset plays at
extension EntryAssignmentData {
    mutating func resetPlaysAt() {
        playsAt.removeAll(keepingCapacity: true)
        playsAtTimes.removeAll(keepingCapacity: true)
        playsAtLocations.removeAll(keepingCapacity: true)
    }
}