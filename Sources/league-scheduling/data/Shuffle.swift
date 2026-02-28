
// MARK: Shuffle
extension AssignmentState {
    /// - Returns: The slot a matchup was sucessfully moved from.
    mutating func shuffle(
        matchup: LeagueMatchupPair,
        day: LeagueDayIndex,
        entriesCount: Int,
        entryDivisions: ContiguousArray<LeagueDivision.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<LeagueRecurringDayLimitInterval>,
        allAvailableMatchups: Set<LeagueMatchupPair>,
        canPlayAtFunc: LeagueScheduleData.CanPlayAtClosure,
        shuffleCanPlayAtFunc: LeagueScheduleData.OptimizedTeamCanPlayAtClosure
    ) -> LeagueAvailableSlot? {
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
            guard shuffleCanPlayAtFunc(
                startingTimes,
                matchupDuration,
                locationTravelDurations,
                swapped.time,
                swapped.location,
                gameGap,
                team1AllowedTimes,
                team1AllowedLocations,
                team1PlaysAt,
                team1PlaysAtTimes,
                team1PlaysAtLocations,
                team1TimeNumbers,
                team1LocationNumbers,
                team1MaxTimeNumbers,
                team1MaxLocationNumbers,
                team2AllowedTimes,
                team2AllowedLocations,
                team2PlaysAt,
                team2PlaysAtTimes,
                team2PlaysAtLocations,
                team2TimeNumbers,
                team2LocationNumbers,
                team2MaxTimeNumbers,
                team2MaxLocationNumbers
            ) else { continue }

            let swappedSlot = swapped.slot
            var homePlaysAt = playsAt[unchecked: swapped.home]
            var awayPlaysAt = playsAt[unchecked: swapped.away]
            homePlaysAt.remove(swappedSlot)
            awayPlaysAt.remove(swappedSlot)

            let homeAllowedTimes = entries[unchecked: swapped.home].gameTimes[unchecked: day]
            let awayAllowedTimes = entries[unchecked: swapped.away].gameTimes[unchecked: day]

            let homeAllowedLocations = entries[unchecked: swapped.home].gameLocations[unchecked: day]
            let awayAllowedLocations = entries[unchecked: swapped.away].gameLocations[unchecked: day]

            var homePlaysAtTimes = playsAtTimes[unchecked: swapped.home]
            var awayPlaysAtTimes = playsAtTimes[unchecked: swapped.away]
            homePlaysAtTimes.remove(swapped.time)
            awayPlaysAtTimes.remove(swapped.time)

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
                return shuffleCanPlayAtFunc(
                    startingTimes,
                    matchupDuration,
                    locationTravelDurations,
                    $0.time,
                    $0.location,
                    gameGap,
                    homeAllowedTimes,
                    homeAllowedLocations,
                    homePlaysAt,
                    homePlaysAtTimes,
                    homePlaysAtLocations,
                    homeAssignedTimes,
                    homeAssignedLocations,
                    maxHomeTimeNumbers,
                    maxHomeLocationNumbers,
                    awayAllowedTimes,
                    awayAllowedLocations,
                    awayPlaysAt,
                    awayPlaysAtTimes,
                    awayPlaysAtLocations,
                    awayAssignedTimes,
                    awayAssignedLocations,
                    maxAwayTimeNumbers,
                    maxAwayLocationNumbers
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
                canPlayAtFunc: canPlayAtFunc
            )
            shuffleHistory.append(.init(day: day, from: swappedSlot, to: slot, pair: swapped.pair))
            return swappedSlot
        }
        return nil
    }
}