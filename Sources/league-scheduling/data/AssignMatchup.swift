
// MARK: Assign Matchup
extension LeagueScheduleData {
    /// - Returns: The `LeagueMatchup` that was successfully assigned.
    @discardableResult
    mutating func assignMatchupPair(
        _ pair: LeagueMatchupPair,
        getAvailableSlotFunc: AvailableSlotClosure,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        allAvailableMatchups: Set<LeagueMatchupPair>
    ) -> LeagueMatchup? {
        return assignmentState.assignMatchupPair(
            pair,
            getAvailableSlotFunc: getAvailableSlotFunc,
            canPlayAt: canPlayAt,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            day: day,
            gameGap: gameGap,
            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups
        )
    }
}
extension AssignmentState {
    /// - Returns: The `LeagueMatchup` that was successfully assigned.
    mutating func assignMatchupPair(
        _ pair: LeagueMatchupPair,
        getAvailableSlotFunc: LeagueScheduleData.AvailableSlotClosure,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        day: LeagueDayIndex,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>
    ) -> LeagueMatchup? {
        var slots = playableSlots(for: pair)
        #if LOG
        let playableSlots = slots
        #endif

        var slot = getAvailableSlotFunc(
            entryMatchupsPerGameDay,
            pair.team1,
            pair.team2,
            playsAtTimes,
            playsAtLocations,
            assignedTimes,
            assignedLocations,
            &slots
        )
        #if LOG
        print("assignMatchupPair;pair=\(pair.description);slot=\(slot == nil ? "nil" : slot!.description);prioritizedEntries=\(prioritizedEntries);slots (\(slots.count))=\(slots.map({ $0.description }));playableSlots (\(playableSlots.count))=\(playableSlots.map({ $0.description }))")
        #endif
        if slot == nil {
            slot = shuffle(
                matchup: pair,
                day: day,
                entriesCount: entriesCount,
                entryDivisions: entryDivisions,
                gameGap: gameGap,
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval, 
                allAvailableMatchups: allAvailableMatchups,
                canPlayAt: canPlayAt
            )
        }
        if let slot {
            return assign(
                matchup: pair,
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
        #if LOG
        print("assignMatchupPair;pair=\(pair.description);slot==nil, removing pair from availableMatchups")
        #endif
        availableMatchups.remove(pair)
        return nil
    }
}

// MARK: Playable slots
extension AssignmentState {
    func playableSlots(for pair: LeagueMatchupPair) -> Set<LeagueAvailableSlot> {
        return Self.playableSlots(for: pair, remainingAllocations: remainingAllocations)
    }
    static func playableSlots(
        for pair: LeagueMatchupPair,
        remainingAllocations: RemainingAllocations
    ) -> Set<LeagueAvailableSlot> {
        return remainingAllocations[unchecked: pair.team1].intersection(remainingAllocations[unchecked: pair.team2])
    }
}