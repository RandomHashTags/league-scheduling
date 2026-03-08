
// MARK: Assign slots
extension LeagueScheduleData {
    /// Assigns available slots for the day, taking into account all schedule settings, previously assigned matchups and generation data.
    /// 
    /// - Returns: Whether assigning the slots was successful.
    mutating func assignSlots() throws(LeagueError) -> Bool {
        let now = clock.now
        let completed = try selectAndAssignSlots()
        executionSteps.append(.init(key: "assignSlots", duration: clock.now - now))
        return completed
    }
    private mutating func selectAndAssignSlots() throws(LeagueError) -> Bool {
        if assignmentState.matchupDuration > 0 {
            return try selectAndAssignSlots(
                canPlayAt: CanPlayAtWithTravelDurations(
                    startingTimes: assignmentState.startingTimes,
                    matchupDuration: assignmentState.matchupDuration,
                    travelDurations: assignmentState.locationTravelDurations
                )
            )
        } else if sameLocationIfB2B {
            return try selectAndAssignSlots(canPlayAt: CanPlayAtSameLocationIfB2B())
        } else {
            return try selectAndAssignSlots(canPlayAt: CanPlayAtNormal())
        }
    }
    private mutating func selectAndAssignSlots(
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) throws(LeagueError) -> Bool {
        #if LOG
        print("AssignSlots;selectAndAssignSlots;assignmentState.matchupDuration=\(assignmentState.matchupDuration);sameLocationIfB2B=\(sameLocationIfB2B);gameGap=\(gameGap);defaultMaxEntryMatchupsPerGameDay=\(defaultMaxEntryMatchupsPerGameDay)")
        #endif

        assignmentState.recalculateAllRemainingAllocations(day: day, entriesCount: entriesCount, gameGap: gameGap, canPlayAt: canPlayAt)
        if gameGap.min == 1 && gameGap.max == 1 && defaultMaxEntryMatchupsPerGameDay != 1 { // back 2 back
            return try assignSlotsB2B(canPlayAt: canPlayAt)
        }
        if prioritizeEarlierTimes {
            if sameLocationIfB2B {
                return try selectAndAssignSlots(selectSlot: SelectSlotEarliestTimeAndSameLocationIfB2B(), canPlayAt: canPlayAt)
            } else {
                return try selectAndAssignSlots(selectSlot: SelectSlotEarliestTime(), canPlayAt: canPlayAt)
            }
        } else {
            return try selectAndAssignSlots(selectSlot: SelectSlotNormal(), canPlayAt: canPlayAt)
        }
    }
    private mutating func selectAndAssignSlots(
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) throws(LeagueError) -> Bool {
        var assignmentIndex = 0
        var fms = failedMatchupSelections[unchecked: assignmentIndex]
        var optimalAvailableMatchups = assignmentState.availableMatchups.filter { !fms.contains($0) }
        var prioritizedMatchups = PrioritizedMatchups<Config>(
            entriesCount: entriesCount,
            prioritizedEntries: assignmentState.prioritizedEntries,
            availableMatchups: optimalAvailableMatchups
        )
        /*let isBack2Back = gameGap.min == 1 && gameGap.max == 1 && entryMatchupsPerGameDay != 1
        var remainingB2BMatchupsToBeScheduled = entryMatchupsPerGameDay
        var previousPrioritizedEntries = Set<LeagueEntry.IDValue>()
        var prioritizedEntriesB2B = Set<LeagueEntry.IDValue>(minimumCapacity: entriesPerMatchup * locations)*/
        while assignmentIndex != expectedMatchupsCount {
            if Task.isCancelled {
                throw .timedOut(function: "selectAndAssignSlots")
            }
            /*combinationLoop: for combination in allowedDivisionCombinations {
                for (divisionIndex, divisionCombination) in combination.enumerated() {
                    let division = LeagueDivision.IDValue(divisionIndex)
                    let divisionMatchups = assignmentState.availableDivisionMatchups[unchecked: division]
                    prioritizedMatchups.update(prioritizedEntries: [], availableMatchups: divisionMatchups)
                    for matchupBlockCount in divisionCombination {
                        guard matchupBlockCount > 0 else { continue }
                    }
                }
            }*/
            guard let originalPair = selectMatchup(prioritizedMatchups: prioritizedMatchups) else { return false }
            var matchup = originalPair
            matchup.balanceHomeAway(assignmentState: assignmentState)
            // successfully selected a matchup
            guard let _ = assignMatchupPair(
                matchup,
                allAvailableMatchups: assignmentState.allMatchups,
                selectSlot: selectSlot,
                canPlayAt: canPlayAt
            ) else {
                // failed to assign matchup, skip it for now
                failedMatchupSelections[unchecked: assignmentIndex].insert(originalPair)
                prioritizedMatchups.remove(originalPair)
                assignmentState.availableMatchups.remove(originalPair)
                continue
            }
            // successfully assigned pair
            assignmentIndex += 1
            if assignmentIndex != expectedMatchupsCount {
                fms = failedMatchupSelections[unchecked: assignmentIndex]
                optimalAvailableMatchups = assignmentState.availableMatchups.filter { !fms.contains($0) }
                /*if isBack2Back {
                    prioritizedEntriesB2B.insert(matchup.team1)
                    prioritizedEntriesB2B.insert(matchup.team2)
                    if assignmentIndex % locations == 0 { // all locations were filled for a time
                        remainingB2BMatchupsToBeScheduled -= 1
                        if remainingB2BMatchupsToBeScheduled == 0 {
                            remainingB2BMatchupsToBeScheduled = entryMatchupsPerGameDay
                            prioritizedEntriesB2B.removeAll(keepingCapacity: true)
                            assignmentState.prioritizedEntries = previousPrioritizedEntries
                        } else {
                            previousPrioritizedEntries = assignmentState.prioritizedEntries
                            assignmentState.prioritizedEntries = prioritizedEntriesB2B
                        }
                    }
                }*/
                prioritizedMatchups.update(
                    prioritizedEntries: assignmentState.prioritizedEntries,
                    availableMatchups: optimalAvailableMatchups
                )
            }
            assignmentState.availableMatchups.remove(originalPair)
        }
        return assignmentState.matchups.count == expectedMatchupsCount
    }
}

// MARK: Select and assign matchup
extension LeagueScheduleData {
    /// Selects and assigns a matchup to an available slot.
    /// 
    /// - Returns: The successfully assigned `LeagueMatchup`.
    static func selectAndAssignMatchup(
        day: LeagueDayIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        assignmentState: inout AssignmentState<Config>,
        shouldSkipSelection: (LeagueMatchupPair) -> Bool,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> LeagueMatchup? {
        var pair:LeagueMatchupPair? = nil
        var prioritizedMatchups = PrioritizedMatchups<Config>(
            entriesCount: entriesCount,
            prioritizedEntries: assignmentState.prioritizedEntries,
            availableMatchups: assignmentState.availableMatchups
        )
        while pair == nil {
            guard let selected = assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups) else { return nil }
            if !shouldSkipSelection(selected) {
                pair = selected
                prioritizedMatchups.update(prioritizedEntries: assignmentState.prioritizedEntries, availableMatchups: assignmentState.availableMatchups)
            } else {
                prioritizedMatchups.remove(selected)
                assignmentState.availableMatchups.remove(selected)
            }
        }
        guard var pair else { return nil }
        pair.balanceHomeAway(assignmentState: assignmentState)

        #if LOG
        print("AssignSlots;selectAndAssignMatchup;pair=\(pair);remainingAllocations[team1]=\(assignmentState.remainingAllocations[unchecked: pair.team1].map({ $0.description }));remainingAllocations[team2]=\(assignmentState.remainingAllocations[unchecked: pair.team2].map({ $0.description }))")
        #endif
        return assignmentState.assignMatchupPair(
            pair,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            day: day,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        )
    }

    static func selectAndAssignMatchup(
        day: LeagueDayIndex,
        entriesPerMatchup: LeagueEntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        assignmentState: inout AssignmentState<Config>,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> LeagueMatchup? {
        var pair:LeagueMatchupPair? = nil
        var prioritizedMatchups = PrioritizedMatchups<Config>(
            entriesCount: entriesCount,
            prioritizedEntries: assignmentState.prioritizedEntries,
            availableMatchups: assignmentState.availableMatchups
        )
        while pair == nil {
            guard let selected = assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups) else { return nil }
            pair = selected
        }
        guard var pair else { return nil }
        pair.balanceHomeAway(assignmentState: assignmentState)

        #if LOG
        print("AssignSlots;selectAndAssignMatchup;pair=\(pair);remainingAllocations[team1]=\(assignmentState.remainingAllocations[unchecked: pair.team1].map({ $0.description }));remainingAllocations[team2]=\(assignmentState.remainingAllocations[unchecked: pair.team2].map({ $0.description }))")
        #endif
        return assignmentState.assignMatchupPair(
            pair,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            day: day,
            gameGap: gameGap,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            allAvailableMatchups: allAvailableMatchups,
            selectSlot: selectSlot,
            canPlayAt: canPlayAt
        )
    }
}