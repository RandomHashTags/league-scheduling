

// MARK: LeagueScheduleData
extension LeagueScheduleData {
    /// Moves the specified matchup to the given slot on the same day.
    mutating func move(
        matchup: LeagueMatchup,
        to slot: LeagueAvailableSlot,
        day: LeagueDayIndex,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        assignmentState.move(
            matchup: matchup,
            to: slot,
            day: day,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            canPlayAt: canPlayAt
        )
    }
}

// MARK: AssignmentState
extension AssignmentState {
    mutating func move(
        matchup: LeagueMatchup,
        to slot: LeagueAvailableSlot,
        day: LeagueDayIndex,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        #if LOG
        print("move;matchup=\(matchup);to slot=\(slot);day=\(day)")
        #endif
        unassign(
            matchup: matchup,
            day: day,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            canPlayAt: canPlayAt
        )
        assign(
            matchup: matchup.pair,
            to: slot,
            day: day,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            canPlayAt: canPlayAt
        )
    }
}