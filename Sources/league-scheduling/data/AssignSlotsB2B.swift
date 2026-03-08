
extension LeagueScheduleData {
    mutating func assignSlotsB2B(
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
                var assignedSlots = Set<LeagueAvailableSlot>()
                var combinationTimeAllocations:ContiguousArray<BitSet64<LeagueTimeIndex>> = .init(
                    repeating: .init(),
                    count: combination.first?.count ?? 10
                )
                for (divisionIndex, divisionCombination) in combination.enumerated() {
                    let division = LeagueDivision.IDValue(divisionIndex)
                    let divisionMatchups = assignmentState.allDivisionMatchups[unchecked: division]
                    assignmentState.availableMatchups = divisionMatchups
                    assignmentState.prioritizedEntries.removeAllKeepingCapacity()
                    for matchup in assignmentState.availableMatchups {
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
                    var disallowedTimes = BitSet64<LeagueTimeIndex>()
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
                        for matchup in matchups {
                            disallowedTimes.insertMember(matchup.time)
                            combinationTimeAllocations[divisionCombinationIndex].insertMember(matchup.time)
                            assignedSlots.insert(matchup.slot)
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