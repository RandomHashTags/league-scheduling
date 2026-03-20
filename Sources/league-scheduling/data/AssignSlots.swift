
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
        var previousPrioritizedEntries = Set<Entry.IDValue>()
        var prioritizedEntriesB2B = Set<Entry.IDValue>(minimumCapacity: entriesPerMatchup * locations)*/
        while assignmentIndex != expectedMatchupsCount {
            if Task.isCancelled {
                throw .timedOut(function: "selectAndAssignSlots")
            }
            /*combinationLoop: for combination in allowedDivisionCombinations {
                for (divisionIndex, divisionCombination) in combination.enumerated() {
                    let division = Division.IDValue(divisionIndex)
                    let divisionMatchups = assignmentState.availableDivisionMatchups[unchecked: division]
                    prioritizedMatchups.update(prioritizedEntries: [], availableMatchups: divisionMatchups)
                    for matchupBlockCount in divisionCombination {
                        guard matchupBlockCount > 0 else { continue }
                    }
                }
            }*/
            guard let originalPair = selectMatchup(prioritizedMatchups: prioritizedMatchups) else { return false }
            var matchup = originalPair
            matchup.balanceHomeAway(rng: &rng, assignmentState: assignmentState)
            // successfully selected a matchup
            guard let _ = assignMatchupPair(
                matchup,
                allAvailableMatchups: assignmentState.allMatchups,
                selectSlot: selectSlot,
                canPlayAt: canPlayAt
            ) else {
                // failed to assign matchup, skip it for now
                failedMatchupSelections[unchecked: assignmentIndex].insertMember(originalPair)
                prioritizedMatchups.remove(originalPair)
                assignmentState.availableMatchups.removeMember(originalPair)
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
            assignmentState.availableMatchups.removeMember(originalPair)
        }
        return assignmentState.matchups.count == expectedMatchupsCount
    }
}

// MARK: Assign slots b2b
extension LeagueScheduleData {
    private mutating func assignSlotsB2B(
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) throws(LeagueError) -> Bool {
        let slots = assignmentState.availableSlots
        let assignmentStateCopy = assignmentState.copy()
        whileLoop: while assignmentState.matchups.count != expectedMatchupsCount {
            if Task.isCancelled {
                throw LeagueError.timedOut(function: "assignSlotsB2B")
            }
            // TODO: pick the optimal combination that should be selected?
            combinationLoop: for combination in allowedDivisionCombinations {
                var assignedSlots = Config.AvailableSlotSet()
                var combinationTimeAllocations:ContiguousArray<Config.TimeSet> = .init(
                    repeating: .init(minimumCapacity: Int(defaultMaxEntryMatchupsPerGameDay)),
                    count: combination.first?.count ?? 10
                )
                for (divisionIndex, divisionCombination) in combination.enumerated() {
                    let division = Division.IDValue(divisionIndex)
                    let divisionMatchups = assignmentState.allDivisionMatchups[unchecked: division]
                    assignmentState.availableMatchups = divisionMatchups
                    assignmentState.prioritizedEntries.removeAllKeepingCapacity()
                    assignmentState.availableMatchups.forEach { matchup in
                        assignmentState.prioritizedEntries.insertMember(matchup.team1)
                        assignmentState.prioritizedEntries.insertMember(matchup.team2)
                    }
                    assignmentState.recalculateAllRemainingAllocations(
                        day: day,
                        entriesCount: entriesCount,
                        gameGap: gameGap,
                        canPlayAt: canPlayAt
                    )
                    #if LOG
                    print("assignSlots;b2b;division=\(division);divisionCombination=\(divisionCombination);matchups.count=\(assignmentState.matchups.count);availableSlots=\(assignmentState.availableSlots.map({ $0.description }));remainingAllocations=\(assignmentState.remainingAllocations.map { $0.map({ $0.description }) })")
                    #endif
                    var disallowedTimes = Config.TimeSet(minimumCapacity: Int(defaultMaxEntryMatchupsPerGameDay))
                    for (divisionCombinationIndex, amount) in divisionCombination.enumerated() {
                        guard amount > 0 else { continue }
                        let combinationTimeAllocation = combinationTimeAllocations[divisionCombinationIndex]
                        if !combinationTimeAllocation.isEmpty {
                            assignmentState.availableSlots = slots.filter { combinationTimeAllocation.contains($0.time) }
                            assignmentState.recalculateAvailableMatchups(
                                day: day,
                                entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
                                allAvailableMatchups: divisionMatchups
                            )
                            assignmentState.recalculateAllRemainingAllocations(
                                day: day,
                                entriesCount: entriesCount,
                                gameGap: gameGap,
                                canPlayAt: canPlayAt
                            )
                        }
                        guard let matchups = assignBlockOfMatchups(
                            amount: amount,
                            division: division,
                            canPlayAt: canPlayAt
                        ) else {
                            assignmentState = assignmentStateCopy.copy()
                            #if LOG
                            print("assignSlotsB2B;failed to assign matchups for division \(division) and combination \(divisionCombination);skipping")
                            #endif
                            continue combinationLoop
                        }
                        matchups.forEach { matchup in
                            disallowedTimes.insertMember(matchup.time)
                            combinationTimeAllocations[divisionCombinationIndex].insertMember(matchup.time)
                            assignedSlots.insertMember(matchup.slot)
                        }
                        assignmentState.availableSlots = slots.filter { !disallowedTimes.contains($0.time) }
                        assignmentState.recalculateAvailableMatchups(
                            day: day,
                            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
                            allAvailableMatchups: divisionMatchups
                        )
                        assignmentState.recalculateAllRemainingAllocations(
                            day: day,
                            entriesCount: entriesCount,
                            gameGap: gameGap,
                            canPlayAt: canPlayAt
                        )
                        #if LOG
                        print("assignSlots;b2b;combination=\(divisionCombination);assigned \(amount) for division \(division);availableSlots=\(assignmentState.availableSlots.map({ "\($0)" }))")
                        #endif
                        // successfully assigned matchup block of <amount> for <division>
                    }
                    assignmentState.availableSlots = slots.filter { !assignedSlots.contains($0) }
                    assignmentState.recalculateAllRemainingAllocations(
                        day: day,
                        entriesCount: entriesCount,
                        gameGap: gameGap,
                        canPlayAt: canPlayAt
                    )
                    #if LOG
                    print("assignSlots;b2b;assigned \(divisionCombination) for division \(division)")
                    #endif
                }
                break whileLoop
            }
            return false
        }
        #if LOG
        print("assignSlotsB2B;assignmentState.matchups.count=\(assignmentState.matchups.count);expectedMatchupsCount=\(expectedMatchupsCount)")
        #endif
        return assignmentState.matchups.count == expectedMatchupsCount
    }
}

// MARK: Select and assign matchup
extension LeagueScheduleData {
    /// Selects and assigns a matchup to an available slot.
    /// 
    /// - Returns: The successfully assigned `Matchup`.
    static func selectAndAssignMatchup(
        day: DayIndex,
        entriesPerMatchup: EntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Config.MatchupPairSet,
        rng: inout some RandomNumberGenerator,
        assignmentState: inout AssignmentState<Config>,
        shouldSkipSelection: (MatchupPair) -> Bool,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        var pair:MatchupPair? = nil
        var prioritizedMatchups = PrioritizedMatchups<Config>(
            entriesCount: entriesCount,
            prioritizedEntries: assignmentState.prioritizedEntries,
            availableMatchups: assignmentState.availableMatchups
        )
        while pair == nil {
            guard let selected = assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups, rng: &rng) else { return nil }
            if !shouldSkipSelection(selected) {
                pair = selected
                prioritizedMatchups.update(prioritizedEntries: assignmentState.prioritizedEntries, availableMatchups: assignmentState.availableMatchups)
            } else {
                prioritizedMatchups.remove(selected)
                assignmentState.availableMatchups.removeMember(selected)
            }
        }
        guard var pair else { return nil }
        pair.balanceHomeAway(rng: &rng, assignmentState: assignmentState)

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
        day: DayIndex,
        entriesPerMatchup: EntriesPerMatchup,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Config.MatchupPairSet,
        rng: inout some RandomNumberGenerator,
        assignmentState: inout AssignmentState<Config>,
        selectSlot: borrowing some SelectSlotProtocol & ~Copyable,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup? {
        var pair:MatchupPair? = nil
        var prioritizedMatchups = PrioritizedMatchups<Config>(
            entriesCount: entriesCount,
            prioritizedEntries: assignmentState.prioritizedEntries,
            availableMatchups: assignmentState.availableMatchups
        )
        while pair == nil {
            guard let selected = assignmentState.selectMatchup(prioritizedMatchups: prioritizedMatchups, rng: &rng) else { return nil }
            pair = selected
        }
        guard var pair else { return nil }
        pair.balanceHomeAway(rng: &rng, assignmentState: assignmentState)

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