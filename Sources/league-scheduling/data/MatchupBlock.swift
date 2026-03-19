
import OrderedCollections

// MARK: Assign block
extension LeagueScheduleData {
    /// - Returns: The assigned block of matchups
    mutating func assignBlockOfMatchups(
        amount: Int,
        division: Division.IDValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> OrderedSet<Matchup>? {
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
                rng: &rng,
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
                rng: &rng,
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
        rng: inout some RandomNumberGenerator,
        assignmentState: inout AssignmentState,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> OrderedSet<Matchup>? {
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
        var adjacentTimes = OrderedSet<TimeIndex>()
        var selectedEntries = OrderedSet<Entry.IDValue>(minimumCapacity: amount * entriesPerMatchup)
        
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
            rng: &rng,
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
                rng: &rng,
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
        let shouldSkipSelection:(MatchupPair) -> Bool = entryMatchupsPerGameDay % 2 == 0 ? {
            var targetEntries = lastSelectedEntries
            targetEntries.append($0.team1)
            targetEntries.append($0.team2)
            let availableMatchups = lastLocalAssignmentStateAvailableMatchups.filter {
                targetEntries.contains($0.team1) && targetEntries.contains($0.team2)
            }
            for entryID in targetEntries {
                if availableMatchups.first(where: { $0.team1 == entryID || $0.team2 == entryID }) == nil {
                    #if LOG
                    print("assignBlockOfMatchups;i == lastMatchupIndex;$0=\($0);targetEntries (\(targetEntries.count))=\(targetEntries);entryID=\(entryID);availableMatchups.first of entryID == nil;skipping $0")
                    #endif
                    return true
                }
            }
            return false
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
            rng: &rng,
            localAssignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection,
            remainingPrioritizedEntries: &remainingPrioritizedEntries,
            selectedEntries: &selectedEntries,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else { return nil }
        // last matchup was successfully assigned; continue
        if var time = adjacentTimes.randomElement(using: &rng) { // TODO: pick an adjacent time that needs to be prioritized over others
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
                        rng: &rng,
                        assignmentState: &localAssignmentState,
                        selectSlot: selectSlot,
                        canPlayAt: canPlayAt
                    ) else { return nil }
                }
                adjacentTimes.remove(time)
                #if LOG
                print("assignBlockOfMatchups;j=\(j);finished time \(time)")
                #endif
                if let nextTime = adjacentTimes.randomElement(using: &rng) {
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
        allAvailableMatchups: OrderedSet<MatchupPair>,
        rng: inout some RandomNumberGenerator,
        localAssignmentState: inout AssignmentState,
        remainingPrioritizedEntries: inout OrderedSet<Entry.IDValue>,
        selectedEntries: inout OrderedSet<Entry.IDValue>,
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
            rng: &rng,
            assignmentState: &localAssignmentState,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.remove(leagueMatchup.home)
        remainingPrioritizedEntries.remove(leagueMatchup.away)
        selectedEntries.append(leagueMatchup.home)
        selectedEntries.append(leagueMatchup.away)
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
        allAvailableMatchups: OrderedSet<MatchupPair>,
        rng: inout some RandomNumberGenerator,
        localAssignmentState: inout AssignmentState,
        shouldSkipSelection: (MatchupPair) -> Bool,
        remainingPrioritizedEntries: inout OrderedSet<Entry.IDValue>,
        selectedEntries: inout OrderedSet<Entry.IDValue>,
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
            rng: &rng,
            assignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.remove(leagueMatchup.home)
        remainingPrioritizedEntries.remove(leagueMatchup.away)
        selectedEntries.append(leagueMatchup.home)
        selectedEntries.append(leagueMatchup.away)
        return leagueMatchup
    }
}