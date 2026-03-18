
@testable import LeagueScheduling
import Testing

struct BalanceHomeAwayExpectations<Config: ScheduleConfiguration>: ScheduleTestsProtocol {
    func expectations(
        cap: MaximumSameOpponentMatchupsCap,
        matchupsPlayedPerDay: ContiguousArray<ContiguousArray<Int>>,
        assignedEntryHomeAways: AssignedEntryHomeAways,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionEntries: [Config.EntryRuntime]
    ) {
        for entry in divisionEntries {
            let entryMatchupsPlayed = matchupsPlayedPerDay.reduce(0, { $0 + $1[unchecked: entry.id] })
            let halfMatchupsPlayed = entryMatchupsPlayed / entryMatchupsPerGameDay
            let (totalHomeGames, totalAwayGames) = Self.totalHomeAwayGamesPlayed(for: entry.id, assignedEntryHomeAways: assignedEntryHomeAways)
            #expect(totalHomeGames + totalAwayGames == entryMatchupsPlayed)
            if totalHomeGames != totalAwayGames {
                if totalHomeGames == halfMatchupsPlayed {
                    #expect(totalAwayGames == halfMatchupsPlayed+1)
                } else if totalAwayGames == halfMatchupsPlayed {
                    #expect(totalHomeGames == halfMatchupsPlayed+1)
                } else {
                    let distance = abs(totalHomeGames.distance(to: totalAwayGames))
                    #expect(distance <= 2, Comment(stringLiteral: "entryMatchupsPerGameDay=\(entryMatchupsPerGameDay);divisionEntries.count=\(divisionEntries.count);entryMatchupsPlayed=\(entryMatchupsPlayed);halfMatchupsPlayed=\(halfMatchupsPlayed);totalHomeGames=\(totalHomeGames);totalAwayGames=\(totalAwayGames)"))
                }
            }
            for opponentEntry in divisionEntries {
                if !entry.isEqual(to: opponentEntry) {
                    let value = assignedEntryHomeAways[unchecked: entry.id][unchecked: opponentEntry.id]
                    let sum = value.sum
                    #expect(sum <= cap)
                    if value.home != value.away {
                        if sum % 2 == 0 { // even number of matchups played against another team
                            #expect(value.home == value.away)
                        }
                    }
                }
            }
        }
    }
    func isBalanced(
        entry: Config.EntryRuntime,
        matchupsPlayedPerDay: ContiguousArray<ContiguousArray<Int>>,
        assignedEntryHomeAways: AssignedEntryHomeAways,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay
    ) -> Bool {
        let entryMatchupsPlayed = matchupsPlayedPerDay.reduce(0, { $0 + $1[unchecked: entry.id] })
        let halfMatchupsPlayed = entryMatchupsPlayed / entryMatchupsPerGameDay
        let (totalHomeGames, totalAwayGames) = Self.totalHomeAwayGamesPlayed(for: entry.id, assignedEntryHomeAways: assignedEntryHomeAways)
        guard totalHomeGames != totalAwayGames else { return true }
        if totalHomeGames == halfMatchupsPlayed {
            return totalAwayGames == halfMatchupsPlayed+1
        } else if totalAwayGames == halfMatchupsPlayed {
            return totalHomeGames == halfMatchupsPlayed+1
        } else {
            let distance = abs(totalHomeGames.distance(to: totalAwayGames))
            return distance <= 2
        }
    }
}
extension BalanceHomeAwayExpectations {
    private static func totalHomeAwayGamesPlayed(
        for team: Entry.IDValue,
        assignedEntryHomeAways: AssignedEntryHomeAways
    ) -> (home: Int, away: Int) {
        var home = 0
        var away = 0
        for value in assignedEntryHomeAways[unchecked: team] {
            home += Int(value.home)
            away += Int(value.away)
        }
        return (home, away)
    }
}

extension Entry.Runtime {
    func isEqual(to rhs: Self) -> Bool {
        id == rhs.id
        && division == rhs.division
        //&& gameDays == rhs.gameDays
        //&& lhs.gameTimes == rhs.gameTimes
        //&& lhs.gameLocations == rhs.gameLocations
        //&& lhs.homeLocations == rhs.homeLocations
        //&& byes == rhs.byes
        //&& lhs.matchupsPerGameDay == rhs.matchupsPerGameDay
    }
}