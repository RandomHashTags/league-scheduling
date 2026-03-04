
// MARK: Assign block
extension LeagueScheduleData {
    /// - Returns: The assigned block of matchups
    mutating func assignBlockOfMatchups(
        amount: Int,
        division: LeagueDivision.IDValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Set<LeagueMatchup>? {
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
            canPlayAt: canPlayAt
        )
    }
}

extension LeagueScheduleData {
    /// - Returns: The assigned block of matchups
    static func assignBlockOfMatchups(
        amount: Int,
        division: LeagueDivision.IDValue,
        day: LeagueDayIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        assignmentState: inout AssignmentState,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Set<LeagueMatchup>? {
        let limit = amount * entryMatchupsPerGameDay
        let getAvailableSlotFunc =
            gameGap.min == 1 && gameGap.max == 1 ? Self.getSlotB2B
            : Self.getSlot
        
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
        var adjacentTimes = Set<LeagueTimeIndex>()
        var selectedEntries = Set<LeagueEntry.IDValue>(minimumCapacity: amount * entriesPerMatchup)
        
        // assign the first matchup, prioritizing the matchup's time
        guard let firstMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            getAvailableSlotFunc: getAvailableSlotFunc,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: localAssignmentState.availableMatchups,
            localAssignmentState: &localAssignmentState,
            shouldSkipSelection: { _ in false },
            canPlayAt: canPlayAt,
            remainingPrioritizedEntries: &remainingPrioritizedEntries,
            selectedEntries: &selectedEntries
        ) else { return nil }
        adjacentTimes = Self.adjacentTimes(for: firstMatchup.time, entryMatchupsPerGameDay: entryMatchupsPerGameDay)
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
                getAvailableSlotFunc: getAvailableSlotFunc,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                allAvailableMatchups: localAssignmentState.availableMatchups,
                localAssignmentState: &localAssignmentState,
                canPlayAt: canPlayAt,
                remainingPrioritizedEntries: &remainingPrioritizedEntries,
                selectedEntries: &selectedEntries
            ) else { return nil }
            #if LOG
            print("assignBlockOfMatchups;remainingAmount=\(remainingAmount);assigned;selectedEntries (\(selectedEntries.count))=\(selectedEntries);localAvailableSlots.count=\(localAssignmentState.availableSlots.count)")
            #endif
            remainingAmount -= 1
        }
        // assign the last matchup
        let lastLocalAssignmentStateAvailableMatchups = localAssignmentState.availableMatchups
        let lastSelectedEntries = selectedEntries
        let shouldSkipSelection:(LeagueMatchupPair) -> Bool = entryMatchupsPerGameDay % 2 == 0 ? {
            var targetEntries = lastSelectedEntries
            targetEntries.insert($0.team1)
            targetEntries.insert($0.team2)
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
            getAvailableSlotFunc: getAvailableSlotFunc,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: localAssignmentState.availableMatchups,
            localAssignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection,
            canPlayAt: canPlayAt,
            remainingPrioritizedEntries: &remainingPrioritizedEntries,
            selectedEntries: &selectedEntries
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
                        getAvailableSlotFunc: getAvailableSlotFunc,
                        canPlayAt: canPlayAt,
                        divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                        allAvailableMatchups: localAssignmentState.availableMatchups,
                        assignmentState: &localAssignmentState,
                    ) else { return nil }
                }
                adjacentTimes.remove(time)
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
        day: LeagueDayIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        getAvailableSlotFunc: AvailableSlotClosure,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        localAssignmentState: inout AssignmentState,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        remainingPrioritizedEntries: inout Set<LeagueEntry.IDValue>,
        selectedEntries: inout Set<LeagueEntry.IDValue>
    ) -> LeagueMatchup? {
        guard let leagueMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            getAvailableSlotFunc: getAvailableSlotFunc,
            canPlayAt: canPlayAt,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            assignmentState: &localAssignmentState
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.remove(leagueMatchup.home)
        remainingPrioritizedEntries.remove(leagueMatchup.away)
        selectedEntries.insert(leagueMatchup.home)
        selectedEntries.insert(leagueMatchup.away)
        return leagueMatchup
    }
    private static func selectAndAssignMatchup(
        day: LeagueDayIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        getAvailableSlotFunc: AvailableSlotClosure,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        localAssignmentState: inout AssignmentState,
        shouldSkipSelection: (LeagueMatchupPair) -> Bool,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        remainingPrioritizedEntries: inout Set<LeagueEntry.IDValue>,
        selectedEntries: inout Set<LeagueEntry.IDValue>
    ) -> LeagueMatchup? {
        guard let leagueMatchup = selectAndAssignMatchup(
            day: day,
            entriesPerMatchup: entriesPerMatchup,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            getAvailableSlotFunc: getAvailableSlotFunc,
            canPlayAt: canPlayAt,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            assignmentState: &localAssignmentState,
            shouldSkipSelection: shouldSkipSelection
        ) else {
            return nil
        }
        // successfully assigned
        remainingPrioritizedEntries.remove(leagueMatchup.home)
        remainingPrioritizedEntries.remove(leagueMatchup.away)
        selectedEntries.insert(leagueMatchup.home)
        selectedEntries.insert(leagueMatchup.away)
        return leagueMatchup
    }
}

// MARK: Adjacent times
extension LeagueScheduleData {
    static func adjacentTimes(
        for time: LeagueTimeIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay
    ) -> Set<LeagueTimeIndex> {
        var adjacentTimes = Set<LeagueTimeIndex>()
        let timeIndex = time % entryMatchupsPerGameDay
        if timeIndex == 0 {
            for i in 1..<LeagueTimeIndex(entryMatchupsPerGameDay) {
                adjacentTimes.insert(time + i)
            }
        } else {
            for i in 1..<timeIndex+1 {
                adjacentTimes.insert(time - i)
            }
            if timeIndex < entryMatchupsPerGameDay-1 {
                for i in 1..<entryMatchupsPerGameDay - timeIndex {
                    adjacentTimes.insert(time + i)
                }
            }
        }
        return adjacentTimes
    }
}