
extension MatchupPair {
    /// Balances home/away allocations, mutating `team1` (home) and `team2` (away) if necessary.
    mutating func balanceHomeAway(
        assignmentState: borrowing AssignmentState
    ) {
        let team1GamesPlayedAgainstTeam2 = assignmentState.assignedEntryHomeAways[unchecked: team1][unchecked: team2]
        // TODO: fix; more/less opponents than game days can make this unbalanced
        if team1GamesPlayedAgainstTeam2.home < team1GamesPlayedAgainstTeam2.away {
            // keep `team1` at home and `team2` at away
        } else if team1GamesPlayedAgainstTeam2.home == team1GamesPlayedAgainstTeam2.away {
            if Self.shouldPlayAtHome(team1: team1, team2: team2, homeMatchups: assignmentState.homeMatchups, awayMatchups: assignmentState.awayMatchups) {
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
        awayMatchups: [UInt8]
    ) -> Bool {
        let home1 = homeMatchups[unchecked: team1]
        let home2 = homeMatchups[unchecked: team2]
        guard home1 == home2 else { return home1 < home2 }

        let away1 = awayMatchups[unchecked: team1]
        let away2 = awayMatchups[unchecked: team2]
        guard away1 == away2 else { return away1 < away2 }
        return Bool.random()
    }
}