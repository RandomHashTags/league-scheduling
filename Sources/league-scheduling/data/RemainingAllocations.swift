
// MARK: New Day
extension AssignmentState {
    mutating func recalculateNewDayRemainingAllocations(
        entriesCount: Int
    ) {
        remainingAllocations = .init(repeating: availableSlots, count: entriesCount)
        var cached = Set<LeagueEntry.IDValue>(minimumCapacity: entriesCount)
        for matchup in availableMatchups {
            recalculateNewDayRemainingAllocations(
                for: matchup,
                cached: &cached
            )
        }
        #if LOG
        print("RemainingAllocations;recalculateNewDayRemainingAllocations;remainingAllocations=\(remainingAllocations.map { $0.count })")
        #endif
    }

    private mutating func recalculateNewDayRemainingAllocations(
        for pair: LeagueMatchupPair,
        cached: inout Set<LeagueEntry.IDValue>
    ) {
        recalculateNewDayRemainingAllocations(
            for: pair.team1,
            cached: &cached
        )
        recalculateNewDayRemainingAllocations(
            for: pair.team2,
            cached: &cached
        )
    }
    private mutating func recalculateNewDayRemainingAllocations(
        for team: LeagueEntry.IDValue,
        cached: inout Set<LeagueEntry.IDValue>
    ) {
        guard !cached.contains(team) else { return }
        cached.insert(team)
        let timeNumbers = assignedTimes[unchecked: team]
        let locationNumbers = assignedLocations[unchecked: team]
        let maxTimeNumbers = maxTimeAllocations[unchecked: team]
        let maxLocationNumbers = maxLocationAllocations[unchecked: team]
        var available = availableSlots
        for slot in availableSlots {
            if timeNumbers[unchecked: slot.time] >= maxTimeNumbers[unchecked: slot.time] || locationNumbers[unchecked: slot.location] >= maxLocationNumbers[unchecked: slot.location] {
                available.remove(slot)
            }
        }
        remainingAllocations[unchecked: team] = available
    }
}

// MARK: All
extension AssignmentState {
    mutating func recalculateAllRemainingAllocations(
        day: LeagueDayIndex,
        entriesCount: Int,
        gameGap: GameGap.TupleValue,
        canPlayAtFunc: LeagueScheduleData.CanPlayAtClosure
    ) {
        var cached = Set<LeagueEntry.IDValue>(minimumCapacity: entriesCount)
        for matchup in availableMatchups {
            recalculateRemainingAllocations(
                day: day,
                for: matchup,
                cached: &cached,
                gameGap: gameGap,
                canPlayAtFunc: canPlayAtFunc
            )
        }
        #if LOG
        print("RemainingAllocations;recalculateAllRemainingAllocations;remainingAllocations=\(remainingAllocations.map { $0.count })")
        #endif
    }

    private mutating func recalculateRemainingAllocations(
        day: LeagueDayIndex,
        for pair: LeagueMatchupPair,
        cached: inout Set<LeagueEntry.IDValue>,
        gameGap: GameGap.TupleValue,
        canPlayAtFunc: LeagueScheduleData.CanPlayAtClosure
    ) {
        recalculateRemainingAllocations(
            day: day,
            for: pair.team1,
            cached: &cached,
            gameGap: gameGap,
            canPlayAtFunc: canPlayAtFunc
        )
        recalculateRemainingAllocations(
            day: day,
            for: pair.team2,
            cached: &cached,
            gameGap: gameGap,
            canPlayAtFunc: canPlayAtFunc
        )
    }

    private mutating func recalculateRemainingAllocations(
        day: LeagueDayIndex,
        for team: LeagueEntry.IDValue,
        cached: inout Set<LeagueEntry.IDValue>,
        gameGap: GameGap.TupleValue,
        canPlayAtFunc: LeagueScheduleData.CanPlayAtClosure
    ) {
        guard !cached.contains(team) else { return }
        cached.insert(team)
        let allowedTimes = entries[unchecked: team].gameTimes[unchecked: day]
        let allowedLocations = entries[unchecked: team].gameLocations[unchecked: day]
        let playsAt = playsAt[unchecked: team]
        let playsAtTimes = playsAtTimes[unchecked: team]
        let playsAtLocations = playsAtLocations[unchecked: team]
        let timeNumbers = assignedTimes[unchecked: team]
        let locationNumbers = assignedLocations[unchecked: team]
        let maxTimeNumbers = maxTimeAllocations[unchecked: team]
        let maxLocationNumbers = maxLocationAllocations[unchecked: team]
        var available = availableSlots
        for slot in availableSlots {
            if !canPlayAtFunc(
                startingTimes,
                matchupDuration,
                locationTravelDurations,
                slot.time,
                slot.location,
                allowedTimes,
                allowedLocations,
                playsAt,
                playsAtTimes,
                playsAtLocations,
                timeNumbers[unchecked: slot.time],
                locationNumbers[unchecked: slot.location],
                maxTimeNumbers[unchecked: slot.time],
                maxLocationNumbers[unchecked: slot.location],
                gameGap
            ) {
                available.remove(slot)
            }
        }
        remainingAllocations[unchecked: team] = available
    }
}