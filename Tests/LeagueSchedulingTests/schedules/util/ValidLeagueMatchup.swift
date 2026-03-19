
@testable import LeagueScheduling

struct ValidLeagueMatchup: CustomStringConvertible, Hashable {
    let day:DayIndex
    let matchup:Matchup

    var description: String {
        "ValidLeagueMatchup(day: \(day), matchup: \(matchup.description))"
    }
}