
import StaticDateTimes

// MARK: Codable
extension LeagueMatchupOccurrence: Codable {
}

// MARK: General
extension LeagueMatchupOccurrence {
    public var interval: LeagueMatchupDuration {
        switch self {
        case .daily:        LeagueMatchupDuration.days(1)
        case .weekly:       LeagueMatchupDuration.weeks(1)
        case .UNRECOGNIZED: LeagueMatchupDuration.days(1)
        }
    }
}