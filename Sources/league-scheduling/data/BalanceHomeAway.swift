
import OrderedCollections

// MARK: Matchup pair
extension MatchupPair {
    /// Balances home/away allocations, mutating `team1` (home) and `team2` (away) if necessary.
    mutating func balanceHomeAway<Config: ScheduleConfiguration>(
        rng: inout some RandomNumberGenerator,
        assignmentState: borrowing AssignmentState<Config>
    ) {
        let team1GamesPlayedAgainstTeam2 = assignmentState.assignedEntryHomeAways[unchecked: team1][unchecked: team2]
        // TODO: fix; more/less opponents than game days can make this unbalanced
        if team1GamesPlayedAgainstTeam2.home < team1GamesPlayedAgainstTeam2.away {
            // keep `team1` at home and `team2` at away
        } else if team1GamesPlayedAgainstTeam2.home == team1GamesPlayedAgainstTeam2.away {
            if Self.shouldPlayAtHome(team1: team1, team2: team2, homeMatchups: assignmentState.homeMatchups, awayMatchups: assignmentState.awayMatchups, rng: &rng) {
                // keep `team1` at home and `team2` at away
                return
            }
            let team1 = team1
            self.team1 = team2
            self.team2 = team1
        } else {
            let team1 = team1
            self.team1 = team2
            self.team2 = team1
        }
    }

    private static func shouldPlayAtHome(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        homeMatchups: [UInt8],
        awayMatchups: [UInt8],
        rng: inout some RandomNumberGenerator
    ) -> Bool {
        let home1 = homeMatchups[unchecked: team1]
        let home2 = homeMatchups[unchecked: team2]
        guard home1 == home2 else { return home1 < home2 }

        let away1 = awayMatchups[unchecked: team1]
        let away2 = awayMatchups[unchecked: team2]
        guard away1 == away2 else { return away1 < away2 }
        return Bool.random(using: &rng)
    }
}

// MARK: LeagueScheduleData
extension LeagueScheduleData {
    mutating func balanceHomeAway(
        generationData: inout LeagueGenerationData
    ) {
        //return
        #if LOG
        print("BalanceHomeAway;LeagueScheduleData;before;home=\(assignmentState.homeMatchups);away=\(assignmentState.awayMatchups)")
        #endif

        let now = clock.now
        var unbalancedEntryIDs = Config.EntryIDSet()
        unbalancedEntryIDs.reserveCapacity(entriesCount)
        var neededFlipsToBalance = [(home: UInt8, away: UInt8)](repeating: (0, 0), count: entriesCount)
        for entryID in 0..<Entry.IDValue(entriesCount) {
            let home = assignmentState.homeMatchups[unchecked: entryID]
            let away = assignmentState.awayMatchups[unchecked: entryID]
            guard home != away && (home + away) % 2 == 0 else {
                continue
            }
            unbalancedEntryIDs.insertMember(entryID)
            let balanceNumber = (home + away) / 2
            if home > balanceNumber {
                neededFlipsToBalance[unchecked: entryID].home = home - balanceNumber
            } else {
                neededFlipsToBalance[unchecked: entryID].away = away - balanceNumber
            }
        }
        guard !unbalancedEntryIDs.isEmpty else {
            appendExecutionStep(now: now)
            return
        }
        var flippable = OrderedSet<FlippableMatchup>()
        for day in 0..<DayIndex(generationData.schedule.count) {
            for matchup in generationData.schedule[unchecked: day] {
                guard unbalancedEntryIDs.contains(matchup.home) && unbalancedEntryIDs.contains(matchup.away) else { continue }
                let homeAway = assignmentState.assignedEntryHomeAways[unchecked: matchup.home][unchecked: matchup.away]
                if homeAway.home != homeAway.away {
                    flippable.append(.init(day: day, matchup: matchup))
                }
            }
        }
        while let entryID = unbalancedEntryIDs.randomElement(using: &rng) {
            var flipped:FlippableMatchup?
            if neededFlipsToBalance[unchecked: entryID].home > 0 {
                flipped = flippable.filter({
                    $0.matchup.home == entryID
                    && neededFlipsToBalance[unchecked: $0.matchup.home].home > 0
                    && neededFlipsToBalance[unchecked: $0.matchup.away].away > 0
                }).randomElement(using: &rng)
            } else {
                flipped = flippable.filter({
                    $0.matchup.away == entryID
                    && neededFlipsToBalance[unchecked: $0.matchup.home].home > 0
                    && neededFlipsToBalance[unchecked: $0.matchup.away].away > 0
                }).randomElement(using: &rng)
            }
            if var flipped {
                flippable.remove(flipped)
                flipHomeAway(matchup: &flipped, neededFlipsToBalance: &neededFlipsToBalance, generationData: &generationData)
                if neededFlipsToBalance[unchecked: flipped.matchup.home] == (0, 0) {
                    unbalancedEntryIDs.removeMember(flipped.matchup.home)
                }
                if neededFlipsToBalance[unchecked: flipped.matchup.away] == (0, 0) {
                    unbalancedEntryIDs.removeMember(flipped.matchup.away)
                }
            } else {
                // TODO: improve? for now we can just skip it
                unbalancedEntryIDs.removeMember(entryID)
            }
        }

        #if LOG
        print("BalanceHomeAway;LeagueScheduleData;after;home=\(assignmentState.homeMatchups);away=\(assignmentState.awayMatchups)")
        #endif

        appendExecutionStep(now: now)
    }
    private mutating func flipHomeAway(
        matchup: inout FlippableMatchup,
        neededFlipsToBalance: inout [(home: UInt8, away: UInt8)],
        generationData: inout LeagueGenerationData
    ) {
        #if LOG
        print("BalanceHomeAway;flipHomeAway;day=\(matchup.day);matchup=\(matchup.matchup.description);neededFlipsToBalance[home]=\(neededFlipsToBalance[unchecked: matchup.matchup.home]);neededFlipsToBalance[away]=\(neededFlipsToBalance[unchecked: matchup.matchup.away])")
        #endif

        generationData.schedule[unchecked: matchup.day].remove(matchup.matchup)
        let home = matchup.matchup.home
        let away = matchup.matchup.away
        neededFlipsToBalance[unchecked: home].home -= 1
        neededFlipsToBalance[unchecked: away].away -= 1

        #if LOG
        assignmentState.homeMatchups[unchecked: home] -= 1
        assignmentState.awayMatchups[unchecked: home] += 1
        assignmentState.homeMatchups[unchecked: away] += 1
        assignmentState.awayMatchups[unchecked: away] -= 1
        #endif

        matchup.matchup.home = away
        matchup.matchup.away = home
        generationData.schedule[unchecked: matchup.day].insertMember(matchup.matchup)
    }
    private struct FlippableMatchup: Hashable, Sendable {
        let day:DayIndex
        var matchup:Matchup
    }

    private mutating func appendExecutionStep(now: ContinuousClock.Instant) {
        let elapsed = clock.now - now
        executionSteps.append(.init(key: "final balanceHomeAway", duration: elapsed))
    }
}