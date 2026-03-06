
struct EntryAssignmentData: Sendable {
    /// Total number of matchups played so far in the schedule.
    var totalNumberOfMatchupsPlayedSoFar = 0

    /// Total number of matchups played at 'home'.
    var totalNumberOfHomeMatchupsPlayedSoFar:UInt8 = 0

    /// Total number of matchups played at 'away'.
    var totalNumberOfAwayMatchupsPlayedSoFar:UInt8 = 0

    var maximumPlayableMatchups:UInt32

    /// Remaining allocations for the current `day`.
    var remainingAllocations:Set<LeagueAvailableSlot>

    /// When entries can play against each other again.
    /// 
    /// - Usage: [opponent `LeagueEntry.IDValue`: `LeagueRecurringDayLimitInterval`]
    var recurringDayLimits:[LeagueRecurringDayLimitInterval]

    var assignedTimes:ContiguousArray<UInt8>
    var assignedLocations:ContiguousArray<UInt8>

    /// Number of times an entry was assigned to play at home or away against another entry.
    /// 
    /// - Usage: [opponent `LeagueEntry.IDValue`: [`LeagueSchedule.HomeAwayValue`]]
    var assignedEntryHomeAways:[LeagueSchedule.HomeAwayValue]

    /// Maximum number of times an entry can play against another entry.
    ///
    /// - Usage: [opponent `LeagueEntry.IDValue`: `maximum allowed matchups for opponent`]
    var maxSameOpponentMatchups:ContiguousArray<LeagueMaximumSameOpponentMatchupsCap>

    var playsAt:Set<LeagueAvailableSlot>
    var playsAtTimes:BitSet64<LeagueTimeIndex>
    var playsAtLocations:BitSet64<LeagueLocationIndex>

    var maxTimeAllocations:[LeagueTimeIndex]
    var maxLocationAllocations:[LeagueLocationIndex]
}

// MARK: Assign
extension EntryAssignmentData {
    mutating func assignHome(
        to slot: LeagueAvailableSlot,
        away: LeagueEntry.IDValue,
        recurringDayLimitInterval: LeagueRecurringDayLimitInterval
    ) {
        totalNumberOfHomeMatchupsPlayedSoFar += 1
        assignedEntryHomeAways[unchecked: away].home += 1
        recurringDayLimits[unchecked: away] += recurringDayLimitInterval
        assign(
            to: slot
        )
    }

    mutating func assignAway(
        to slot: LeagueAvailableSlot,
        home: LeagueEntry.IDValue,
        recurringDayLimitInterval: LeagueRecurringDayLimitInterval
    ) {
        totalNumberOfAwayMatchupsPlayedSoFar += 1
        assignedEntryHomeAways[unchecked: home].away += 1
        recurringDayLimits[unchecked: home] += recurringDayLimitInterval
        assign(
            to: slot
        )
    }

    private mutating func assign(
        to slot: LeagueAvailableSlot
    ) {
        totalNumberOfMatchupsPlayedSoFar += 1
        assignedTimes[unchecked: slot.time] += 1
        assignedLocations[unchecked: slot.location] += 1
        playsAt.insert(slot)
        playsAtTimes.insertMember(slot.time)
        playsAtLocations.insertMember(slot.location)
    }
}

// MARK: Reset plays at
extension EntryAssignmentData {
    mutating func resetPlaysAt() {
        playsAt.removeAll(keepingCapacity: true)
        playsAtTimes.removeAll()
        playsAtLocations.removeAll()
    }
}