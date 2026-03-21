
// MARK: New Day
extension AssignmentState {
    mutating func recalculateNewDayPossibleAllocations(
        entriesCount: Int
    ) {
        possibleAllocations = .init(repeating: availableSlots, count: entriesCount)
        var cached = Set<Entry.IDValue>(minimumCapacity: entriesCount)
        availableMatchups.forEach { matchup in
            recalculateNewDayPossibleAllocations(
                for: matchup,
                cached: &cached
            )
        }
        #if LOG
        print("PossibleAllocations;recalculateNewDayPossibleAllocations;possibleAllocations=\(possibleAllocations.map { $0.count })")
        #endif
    }

    private mutating func recalculateNewDayPossibleAllocations(
        for pair: MatchupPair,
        cached: inout Set<Entry.IDValue>
    ) {
        recalculateNewDayPossibleAllocations(
            for: pair.team1,
            cached: &cached
        )
        recalculateNewDayPossibleAllocations(
            for: pair.team2,
            cached: &cached
        )
    }
    private mutating func recalculateNewDayPossibleAllocations(
        for team: Entry.IDValue,
        cached: inout Set<Entry.IDValue>
    ) {
        guard !cached.contains(team) else { return }
        cached.insert(team)
        let timeNumbers = assignedTimes[unchecked: team]
        let locationNumbers = assignedLocations[unchecked: team]
        let maxTimeNumbers = maxTimeAllocations[unchecked: team]
        let maxLocationNumbers = maxLocationAllocations[unchecked: team]
        var available = availableSlots
        availableSlots.forEach { slot in
            if timeNumbers[unchecked: slot.time] >= maxTimeNumbers[unchecked: slot.time] || locationNumbers[unchecked: slot.location] >= maxLocationNumbers[unchecked: slot.location] {
                available.removeMember(slot)
            }
        }
        possibleAllocations[unchecked: team] = available
    }
}

// MARK: All
extension AssignmentState {
    mutating func recalculateAllPossibleAllocations(
        day: DayIndex,
        entriesCount: Int,
        gameGap: GameGap.TupleValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        var cached = Set<Entry.IDValue>(minimumCapacity: entriesCount)
        availableMatchups.forEach { matchup in
            recalculatePossibleAllocations(
                day: day,
                for: matchup,
                cached: &cached,
                gameGap: gameGap,
                canPlayAt: canPlayAt
            )
        }
        #if LOG
        print("PossibleAllocations;recalculateAllPossibleAllocations;possibleAllocations=\(possibleAllocations.map { $0.count })")
        #endif
    }

    private mutating func recalculatePossibleAllocations(
        day: DayIndex,
        for pair: MatchupPair,
        cached: inout Set<Entry.IDValue>,
        gameGap: GameGap.TupleValue,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) {
        recalculatePossibleAllocations(
            day: day,
            for: pair.team1,
            cached: &cached,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
        recalculatePossibleAllocations(
            day: day,
            for: pair.team2,
            cached: &cached,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
    }

    private mutating func recalculatePossibleAllocations(
        day: DayIndex,
        for team: Entry.IDValue,
        cached: inout Set<Entry.IDValue>,
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
        availableSlots.forEach { slot in
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
                available.removeMember(slot)
            }
        }
        possibleAllocations[unchecked: team] = available
    }
}