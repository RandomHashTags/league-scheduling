
// MARK: Unassign
extension AssignmentState {
    mutating func unassign(
        matchup: LeagueMatchup,
        day: LeagueDayIndex,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        canPlayAtFunc: LeagueScheduleData.CanPlayAtClosure
    ) {
        let recurringDayLimitInterval = divisionRecurringDayLimitInterval[unchecked: entryDivisions[unchecked: matchup.home]]
        recurringDayLimits[unchecked: matchup.home][unchecked: matchup.away] -= recurringDayLimitInterval
        recurringDayLimits[unchecked: matchup.away][unchecked: matchup.home] -= recurringDayLimitInterval
        decrementAssignData(home: matchup.home, away: matchup.away, slot: matchup.slot)
        removePlaysAt(home: matchup.home, away: matchup.away, slot: matchup.slot)
        availableSlots.insert(matchup.slot)
        matchups.remove(matchup)

        recalculateAvailableMatchups(
            day: day,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            allAvailableMatchups: allAvailableMatchups
        )
        recalculateAllRemainingAllocations(
            day: day,
            entriesCount: entriesCount,
            gameGap: gameGap,
            canPlayAtFunc: canPlayAtFunc
        )
        #if LOG
        print("unassign;day=\(day);matchup=\(matchup);availableMatchups.count=\(availableMatchups.count);remainingAllocations=\(remainingAllocations.map { $0.count })")
        #endif
    }
}

// MARK: Decrement assign data
extension AssignmentState {
    mutating func decrementAssignData(
        home: LeagueEntry.IDValue,
        away: LeagueEntry.IDValue,
        slot: LeagueAvailableSlot
    ) {
        Self.subtractClampingOverflow(number: &numberOfAssignedMatchups[unchecked: home], amount: 1)
        Self.subtractClampingOverflow(number: &numberOfAssignedMatchups[unchecked: away], amount: 1)
        Self.subtractClampingOverflow(number: &assignedTimes[unchecked: home][unchecked: slot.time], amount: 1)
        Self.subtractClampingOverflow(number: &assignedTimes[unchecked: away][unchecked: slot.time], amount: 1)
        Self.subtractClampingOverflow(number: &assignedLocations[unchecked: home][unchecked: slot.location], amount: 1)
        Self.subtractClampingOverflow(number: &assignedLocations[unchecked: away][unchecked: slot.location], amount: 1)

        Self.subtractClampingOverflow(number: &assignedEntryHomeAways[unchecked: home][unchecked: away].home, amount: 1)
        Self.subtractClampingOverflow(number: &assignedEntryHomeAways[unchecked: away][unchecked: home].away, amount: 1)
        Self.subtractClampingOverflow(number: &homeMatchups[unchecked: home], amount: 1)
        Self.subtractClampingOverflow(number: &awayMatchups[unchecked: away], amount: 1)
    }

    static func subtractClampingOverflow<T: FixedWidthInteger>(
        number: inout T,
        amount: T
    ) {
        let result = number.subtractingReportingOverflow(amount)
        number = result.overflow ? T.min : result.partialValue
    }

    mutating func removePlaysAt(
        home: LeagueEntry.IDValue,
        away: LeagueEntry.IDValue,
        slot: LeagueAvailableSlot
    ) {
        playsAt[unchecked: home].remove(slot)
        playsAt[unchecked: away].remove(slot)
        playsAtTimes[unchecked: home].remove(slot.time)
        playsAtTimes[unchecked: away].remove(slot.time)
        playsAtLocations[unchecked: home].remove(slot.location)
        playsAtLocations[unchecked: away].remove(slot.location)
    }
}

// MARK: Recalculate available matchups
extension AssignmentState {
    mutating func recalculateAvailableMatchups(
        day: LeagueDayIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        allAvailableMatchups: Set<LeagueMatchupPair>
    ) {
        availableMatchups = allAvailableMatchups.filter({
            guard assignedEntryHomeAways[unchecked: $0.team1][unchecked: $0.team2].sum < maxSameOpponentMatchups[unchecked: $0.team1][unchecked: $0.team2]
                && playsAtTimes[unchecked: $0.team1].count < entryMatchupsPerGameDay
                && playsAtTimes[unchecked: $0.team2].count < entryMatchupsPerGameDay
            else {
                return false
            }
            return true
        })
    }
}