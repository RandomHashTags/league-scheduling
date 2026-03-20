
import OrderedCollections

// MARK: Shuffle
extension AssignmentState {
    /// - Returns: The slot a matchup was sucessfully moved from.
    mutating func shuffle(
        matchup: MatchupPair,
        day: DayIndex,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        allAvailableMatchups: Config.MatchupPairSet,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> AvailableSlot? {
        // TODO: fix (can get stuck shuffling the same matchup to the same slot)
        let team1AllowedTimes = entries[unchecked: matchup.team1].gameTimes[unchecked: day]
        let team1AllowedLocations = entries[unchecked: matchup.team1].gameLocations[unchecked: day]
        let team1PlaysAt = playsAt[unchecked: matchup.team1]
        let team1PlaysAtTimes = playsAtTimes[unchecked: matchup.team1]
        let team1PlaysAtLocations = playsAtLocations[unchecked: matchup.team1]
        let team1TimeNumbers = assignedTimes[unchecked: matchup.team1]
        let team1LocationNumbers = assignedLocations[unchecked: matchup.team1]
        let team1MaxTimeNumbers = maxTimeAllocations[unchecked: matchup.team1]
        let team1MaxLocationNumbers = maxLocationAllocations[unchecked: matchup.team1]
        let team2AllowedTimes = entries[unchecked: matchup.team2].gameTimes[unchecked: day]
        let team2AllowedLocations = entries[unchecked: matchup.team2].gameLocations[unchecked: day]
        let team2PlaysAt = playsAt[unchecked: matchup.team2]
        let team2PlaysAtTimes = playsAtTimes[unchecked: matchup.team2]
        let team2PlaysAtLocations = playsAtLocations[unchecked: matchup.team2]
        let team2TimeNumbers = assignedTimes[unchecked: matchup.team2]
        let team2LocationNumbers = assignedLocations[unchecked: matchup.team2]
        let team2MaxTimeNumbers = maxTimeAllocations[unchecked: matchup.team2]
        let team2MaxLocationNumbers = maxLocationAllocations[unchecked: matchup.team2]
        for swapped in matchups {
            // make sure the failed assigned matchup is allowed to go where the assigned matchup is
            guard canPlayAt.test(
                time: swapped.time,
                location: swapped.location,
                allowedTimes: team1AllowedTimes,
                allowedLocations: team1AllowedLocations,
                playsAt: team1PlaysAt,
                playsAtTimes: team1PlaysAtTimes,
                playsAtLocations: team1PlaysAtLocations,
                timeNumber: team1TimeNumbers[unchecked: swapped.time],
                locationNumber: team1LocationNumbers[unchecked: swapped.location],
                maxTimeNumber: UInt8(team1MaxTimeNumbers[unchecked: swapped.time]),
                maxLocationNumber: UInt8(team1MaxLocationNumbers[unchecked: swapped.location]),
                gameGap: gameGap
            ) && canPlayAt.test(
                time: swapped.time,
                location: swapped.location,
                allowedTimes: team2AllowedTimes,
                allowedLocations: team2AllowedLocations,
                playsAt: team2PlaysAt,
                playsAtTimes: team2PlaysAtTimes,
                playsAtLocations: team2PlaysAtLocations,
                timeNumber: team2TimeNumbers[unchecked: swapped.time],
                locationNumber: team2LocationNumbers[unchecked: swapped.location],
                maxTimeNumber: UInt8(team2MaxTimeNumbers[unchecked: swapped.time]),
                maxLocationNumber: UInt8(team2MaxLocationNumbers[unchecked: swapped.location]),
                gameGap: gameGap
            ) else {
                continue
            }

            let swappedSlot = swapped.slot
            var homePlaysAt = playsAt[unchecked: swapped.home]
            var awayPlaysAt = playsAt[unchecked: swapped.away]
            homePlaysAt.removeMember(swappedSlot)
            awayPlaysAt.removeMember(swappedSlot)

            let homeAllowedTimes = entries[unchecked: swapped.home].gameTimes[unchecked: day]
            let awayAllowedTimes = entries[unchecked: swapped.away].gameTimes[unchecked: day]

            let homeAllowedLocations = entries[unchecked: swapped.home].gameLocations[unchecked: day]
            let awayAllowedLocations = entries[unchecked: swapped.away].gameLocations[unchecked: day]

            var homePlaysAtTimes = playsAtTimes[unchecked: swapped.home]
            var awayPlaysAtTimes = playsAtTimes[unchecked: swapped.away]
            homePlaysAtTimes.removeMember(swapped.time)
            awayPlaysAtTimes.removeMember(swapped.time)

            var homePlaysAtLocations = playsAtLocations[unchecked: swapped.home]
            var awayPlaysAtLocations = playsAtLocations[unchecked: swapped.away]
            homePlaysAtLocations.remove(swapped.location)
            awayPlaysAtLocations.remove(swapped.location)

            let homeAssignedTimes = assignedTimes[unchecked: swapped.home]
            let awayAssignedTimes = assignedTimes[unchecked: swapped.away]

            let homeAssignedLocations = assignedLocations[unchecked: swapped.home]
            let awayAssignedLocations = assignedLocations[unchecked: swapped.away]

            let maxHomeTimeNumbers = maxTimeAllocations[unchecked: swapped.home]
            let maxHomeLocationNumbers = maxLocationAllocations[unchecked: swapped.home]
            let maxAwayTimeNumbers = maxTimeAllocations[unchecked: swapped.away]
            let maxAwayLocationNumbers = maxLocationAllocations[unchecked: swapped.away]
            guard let slot = availableSlots.first(where: {
                return canPlayAt.test(
                    time: $0.time,
                    location: $0.location,
                    allowedTimes: homeAllowedTimes,
                    allowedLocations: homeAllowedLocations,
                    playsAt: homePlaysAt,
                    playsAtTimes: homePlaysAtTimes,
                    playsAtLocations: homePlaysAtLocations,
                    timeNumber: homeAssignedTimes[unchecked: $0.time],
                    locationNumber: homeAssignedLocations[unchecked: $0.location],
                    maxTimeNumber: UInt8(maxHomeTimeNumbers[unchecked: $0.time]),
                    maxLocationNumber: UInt8(maxHomeLocationNumbers[unchecked: $0.location]),
                    gameGap: gameGap
                ) && canPlayAt.test(
                    time: $0.time,
                    location: $0.location,
                    allowedTimes: awayAllowedTimes,
                    allowedLocations: awayAllowedLocations,
                    playsAt: awayPlaysAt,
                    playsAtTimes: awayPlaysAtTimes,
                    playsAtLocations: awayPlaysAtLocations,
                    timeNumber: awayAssignedTimes[unchecked: $0.time],
                    locationNumber: awayAssignedLocations[unchecked: $0.location],
                    maxTimeNumber: UInt8(maxAwayTimeNumbers[unchecked: $0.time]),
                    maxLocationNumber: UInt8(maxAwayLocationNumbers[unchecked: $0.location]),
                    gameGap: gameGap
                )
            }) else { continue }

            #if LOG
            print("shuffle;day=\(day);moved \(swapped) to \(slot) to make room for \(matchup)")
            #endif
            move(
                matchup: swapped,
                to: slot,
                day: day,
                entriesCount: entriesCount,
                entryDivisions: entryDivisions,
                gameGap: gameGap,
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
                allAvailableMatchups: allAvailableMatchups,
                canPlayAt: canPlayAt
            )
            shuffleHistory.append(.init(day: day, from: swappedSlot, to: slot, pair: swapped.pair))
            return swappedSlot
        }
        return nil
    }
}