
@testable import LeagueScheduling

struct MatchupsPlayedPerGameDay {
    static func get(
        gameDays: DayIndex,
        entriesCount: Int,
        schedule: ContiguousArray<Config.MatchupSet>
    ) -> ContiguousArray<ContiguousArray<Int>> {
        var matchupsPlayedPerDay = ContiguousArray(
            repeating: ContiguousArray(repeating: 0, count: entriesCount),
            count: gameDays
        )
        for (dayIndex, matchups) in schedule.enumerated() {
            for matchup in matchups {
                matchupsPlayedPerDay[unchecked: dayIndex][unchecked: matchup.home] += 1
                matchupsPlayedPerDay[unchecked: dayIndex][unchecked: matchup.away] += 1
            }
        }
        return matchupsPlayedPerDay
    }
}