
// MARK: Assign Matchup
extension LeagueScheduleData {
    /// - Returns: The `Matchup` that was successfully assigned.
    @discardableResult
    mutating func assignMatchupPair(
        _ pair: MatchupPair,
        allAvailableMatchups: Set<MatchupPair>,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        return assignmentState.assignMatchupPair(
            pair,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            day: day,
            gameGap: gameGap,
            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        )
    }
}

extension AssignmentState {
    /// - Returns: The `Matchup` that was successfully assigned.
    mutating func assignMatchupPair(
        _ pair: MatchupPair,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        day: DayIndex,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Set<MatchupPair>,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        var slots = playableSlots(for: pair)
        #if LOG
        let playableSlots = slots
        #endif

        var slot = selectSlot.select(
            team1: pair.team1,
            team2: pair.team2,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            playableSlots: &slots
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
    func playableSlots(for pair: MatchupPair) -> Set<AvailableSlot> {
        return Self.playableSlots(for: pair, remainingAllocations: remainingAllocations)
    }
    static func playableSlots(
        for pair: MatchupPair,
        remainingAllocations: RemainingAllocations
    ) -> Set<AvailableSlot> {
        return remainingAllocations[unchecked: pair.team1].intersection(remainingAllocations[unchecked: pair.team2])
    }
}