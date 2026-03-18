
// MARK: Assign block
extension LeagueScheduleData {
    /// - Returns: The assigned block of matchups
    mutating func assignBlockOfMatchups(
        amount: Int,
        division: Division.IDValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Set<Matchup>? {
        if gameGap.min == 1 && gameGap.max == 1 {
            return Self.assignBlockOfMatchups(
                amount: amount,
                division: division,
                day: day,
                entriesPerMatchup: entriesPerMatchup,
                entriesCount: entriesCount,
                entryDivisions: entryDivisions,
                gameGap: gameGap,
                entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                assignmentState: &assignmentState,
                selectSlot: SelectSlotB2B(entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay),
                canPlayAt: canPlayAt
            )
        } else {
            return Self.assignBlockOfMatchups(
                amount: amount,
                division: division,
                day: day,
                entriesPerMatchup: entriesPerMatchup,
                entriesCount: entriesCount,
                entryDivisions: entryDivisions,
                gameGap: gameGap,
                entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                assignmentState: &assignmentState,
                selectSlot: SelectSlotNormal(),
                canPlayAt: canPlayAt
            )
        }
    }
}

extension LeagueScheduleData {
    /// - Returns: The assigned block of matchups
    static func assignBlockOfMatchups(
        amount: Int,
        division: Division.IDValue,
        day: DayIndex,
        entriesPerMatchup: EntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        assignmentState: inout AssignmentState<Config>,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Set<Matchup>? {
        let limit = amount * entryMatchupsPerGameDay
        var remainingPrioritizedEntries = assignmentState.prioritizedEntries
        var remainingAvailableSlots = assignmentState.availableSlots
        var localAssignmentState = assignmentState.copy()
        localAssignmentState.matchups.removeAll(keepingCapacity: true)
        localAssignmentState.recalculateAvailableMatchups(
            day: day,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            allAvailableMatchups: assignmentState.allDivisionMatchups[unchecked: division]
        )
        #if LOG
        print("assignBlockOfMatchups;amount=\(amount);day=\(day);division=\(division);localAssignmentState.availableMatchups (\(localAssignmentState.availableMatchups.count))=\(localAssignmentState.availableMatchups.map({ $0.description }))")
        print("assignedEntryHomeAways=\(localAssignmentState.assignedEntryHomeAways.map { $0.map { $0.sum } })")
        #endif
        // assign initial matchups
        var adjacentTimes = Config.TimeSet()
        var selectedEntries = Config.EntryIDSet()
        selectedEntries.reserveCapacity(amount * entriesPerMatchup)
        
        // assign the first matchup, prioritizing the matchup's time
        guard let firstMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: localAssignmentState.availableMatchups,
            localAssignmentState: &localAssignmentState,
            shouldSkipSelection: { _ in false },
            remainingPrioritizedEntries: &remainingPrioritizedEntries,
            selectedEntries: &selectedEntries,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else { return nil }
        adjacentTimes = calculateAdjacentTimes(for: firstMatchup.time, entryMatchupsPerGameDay: entryMatchupsPerGameDay)
        localAssignmentState.availableSlots = localAssignmentState.availableSlots.filter { $0.time == firstMatchup.time }
        localAssignmentState.recalculateAllRemainingAllocations(
            day: day,
            entriesCount: entriesCount,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
        // assign matchups, except the last one
        var remainingAmount = amount-2
        while remainingAmount > 0 {
            guard let _ = selectAndAssignMatchup(
                day: day,
                entriesPerMatchup: entriesPerMatchup,
                entriesCount: entriesCount,
                entryDivisions: entryDivisions,
                gameGap: gameGap,
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                allAvailableMatchups: localAssignmentState.availableMatchups,
                localAssignmentState: &localAssignmentState,
                remainingPrioritizedEntries: &remainingPrioritizedEntries,
                selectedEntries: &selectedEntries,
                selectSlot: selectSlot,
                canPlayAt: canPlayAt
            ) else { return nil }
            #if LOG
            print("assignBlockOfMatchups;remainingAmount=\(remainingAmount);assigned;selectedEntries (\(selectedEntries.count))=\(selectedEntries);localAvailableSlots.count=\(localAssignmentState.availableSlots.count)")
            #endif
            remainingAmount -= 1
        }
        // assign the last matchup
        let lastLocalAssignmentStateAvailableMatchups = localAssignmentState.availableMatchups
        let lastSelectedEntries = selectedEntries
        let shouldSkipSelection:(MatchupPair) -> Bool = entryMatchupsPerGameDay % 2 == 0 ? { pair in
            var targetEntries = lastSelectedEntries
            targetEntries.insertMember(pair.team1)
            targetEntries.insertMember(pair.team2)
            let availableMatchups = lastLocalAssignmentStateAvailableMatchups.filter {
                targetEntries.contains($0.team1) && targetEntries.contains($0.team2)
            }
            return targetEntries.forEachWithReturn { entryID in
                if availableMatchups.first(where: { $0.team1 == entryID || $0.team2 == entryID }) == nil {
                    #if LOG
                    print("assignBlockOfMatchups;i == lastMatchupIndex;pair=\(pair);targetEntries (\(targetEntries.count))=\(targetEntries);entryID=\(entryID);availableMatchups.first of entryID == nil;skipping $0")
                    #endif
                    return true
                }
                return nil
            } ?? false
        } : { _ in false }
        guard let _ = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: localAssignmentState.availableMatchups,
            localAssignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection,
            remainingPrioritizedEntries: &remainingPrioritizedEntries,
            selectedEntries: &selectedEntries,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else { return nil }
        // last matchup was successfully assigned; continue
        if var time = adjacentTimes.randomElement() { // TODO: pick an adjacent time that needs to be prioritized over others
            // assign matchups from previously scheduled entries until they have played all their games
            localAssignmentState.availableMatchups = localAssignmentState.availableMatchups.filter {
                selectedEntries.contains($0.team1) && selectedEntries.contains($0.team2)
            }
            localAssignmentState.availableSlots = assignmentState.availableSlots.filter { $0.time == time }
            localAssignmentState.recalculateAllRemainingAllocations(
                day: day,
                entriesCount: entriesCount,
                gameGap: gameGap,
                canPlayAt: canPlayAt
            )
            for j in 1..<entryMatchupsPerGameDay {
                for _ in 0..<amount {
                    localAssignmentState.prioritizedEntries = selectedEntries
                    guard let leagueMatchup = selectAndAssignMatchup(
                        day: day,
                        entriesPerMatchup: entriesPerMatchup,
                        entriesCount: entriesCount,
                        entryDivisions: entryDivisions,
                        gameGap: gameGap,
                        entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                        divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                        allAvailableMatchups: localAssignmentState.availableMatchups,
                        assignmentState: &localAssignmentState,
                        selectSlot: selectSlot,
                        canPlayAt: canPlayAt
                    ) else { return nil }
                }
                adjacentTimes.removeMember(time)
                #if LOG
                print("assignBlockOfMatchups;j=\(j);finished time \(time)")
                #endif
                if let nextTime = adjacentTimes.randomElement() {
                    time = nextTime
                }
            }
        }
        guard localAssignmentState.matchups.count == limit else { return nil }
        let previousMatchups = assignmentState.matchups
        assignmentState = localAssignmentState.copy()
        assignmentState.matchups.formUnion(previousMatchups)
        for matchup in localAssignmentState.matchups {
            remainingAvailableSlots.remove(matchup.slot)
        }
        assignmentState.availableSlots = remainingAvailableSlots
        assignmentState.prioritizedEntries = remainingPrioritizedEntries
        return localAssignmentState.matchups
    }
}

// MARK: Select and assign
extension LeagueScheduleData {
    private static func selectAndAssignMatchup(
        day: DayIndex,
        entriesPerMatchup: EntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Set<MatchupPair>,
        localAssignmentState: inout AssignmentState<Config>,
        remainingPrioritizedEntries: inout Config.EntryIDSet,
        selectedEntries: inout Config.EntryIDSet,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        guard let leagueMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            assignmentState: &localAssignmentState,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.removeMember(leagueMatchup.home)
        remainingPrioritizedEntries.removeMember(leagueMatchup.away)
        selectedEntries.insertMember(leagueMatchup.home)
        selectedEntries.insertMember(leagueMatchup.away)
        return leagueMatchup
    }
    private static func selectAndAssignMatchup(
        day: DayIndex,
        entriesPerMatchup: EntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Set<MatchupPair>,
        localAssignmentState: inout AssignmentState<Config>,
        shouldSkipSelection: (MatchupPair) -> Bool,
        remainingPrioritizedEntries: inout Config.EntryIDSet,
        selectedEntries: inout Config.EntryIDSet,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        guard let leagueMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            assignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.removeMember(leagueMatchup.home)
        remainingPrioritizedEntries.removeMember(leagueMatchup.away)
        selectedEntries.insertMember(leagueMatchup.home)
        selectedEntries.insertMember(leagueMatchup.away)
        return leagueMatchup
    }
}