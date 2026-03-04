
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
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        var cached = Set<LeagueEntry.IDValue>(minimumCapacity: entriesCount)
        for matchup in availableMatchups {
            recalculateRemainingAllocations(
                day: day,
                for: matchup,
                cached: &cached,
                gameGap: gameGap,
                canPlayAt: canPlayAt
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
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        recalculateRemainingAllocations(
            day: day,
            for: pair.team1,
            cached: &cached,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
        recalculateRemainingAllocations(
            day: day,
            for: pair.team2,
            cached: &cached,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
    }

    private mutating func recalculateRemainingAllocations(
        day: LeagueDayIndex,
        for team: LeagueEntry.IDValue,
        cached: inout Set<LeagueEntry.IDValue>,
        gameGap: GameGap.TupleValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
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
            if !canPlayAt.test(
                time: slot.time,
                location: slot.location,
                allowedTimes: allowedTimes,
                allowedLocations: allowedLocations,
                playsAt: playsAt,
                playsAtTimes: playsAtTimes,
                playsAtLocations: playsAtLocations,
                timeNumber: timeNumbers[unchecked: slot.time],
                locationNumber: locationNumbers[unchecked: slot.location],
                maxTimeNumber: UInt8(maxTimeNumbers[unchecked: slot.time]),
                maxLocationNumber: UInt8(maxLocationNumbers[unchecked: slot.location]),
                gameGap: gameGap
            ) {
                available.remove(slot)
            }
        }
        remainingAllocations[unchecked: team] = available
    }
}