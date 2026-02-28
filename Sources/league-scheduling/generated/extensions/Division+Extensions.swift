
// MARK: Codable
extension LeagueDivision: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        }
        if let dayOfWeek = try container.decodeIfPresent(UInt32.self, forKey: .dayOfWeek) {
            self.dayOfWeek = dayOfWeek
        }
        if let gameDays = try container.decodeIfPresent(LitLeagues_Leagues_GameDays.self, forKey: .gameDays) {
            self.gameDays = gameDays
        }
        if let byes = try container.decodeIfPresent(LitLeagues_Leagues_Byes.self, forKey: .byes) {
            self.byes = byes
        }
        if let gameGaps = try container.decodeIfPresent(LitLeagues_Leagues_GameGaps.self, forKey: .gameGaps) {
            self.gameGaps = gameGaps
        }
        if let gameDayTimes = try container.decodeIfPresent(LitLeagues_Leagues_GameDayTimes.self, forKey: .gameDayTimes) {
            self.gameDayTimes = gameDayTimes
        }
        if let gameDayLocations = try container.decodeIfPresent(LitLeagues_Leagues_GameDayLocations.self, forKey: .gameDayLocations) {
            self.gameDayLocations = gameDayLocations
        }
        if let matchupDurations = try container.decodeIfPresent(LitLeagues_Leagues_DivisionMatchupDurations.self, forKey: .matchupDurations) {
            self.matchupDurations = matchupDurations
        }
        if let locationTimeExclusivities = try container.decodeIfPresent(LeagueLocationTimeExclusivities.self, forKey: .locationTimeExclusivities) {
            self.locationTimeExclusivities = locationTimeExclusivities
        }
        if let travelDurations = try container.decodeIfPresent(LeagueLocationTravelDurations.self, forKey: .travelDurations) {
            self.travelDurations = travelDurations
        }
        if let opponents = try container.decodeIfPresent(LitLeagues_Leagues_DivisionOpponents.self, forKey: .opponents) {
            self.opponents = opponents
        }
        if let maxSameOpponentMatchups = try container.decodeIfPresent(LeagueMaximumSameOpponentMatchupsCap.self, forKey: .maxSameOpponentMatchups) {
            self.maxSameOpponentMatchups = maxSameOpponentMatchups
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasName {
            try container.encode(name, forKey: .name)
        }
        if hasDayOfWeek {
            try container.encode(dayOfWeek, forKey: .dayOfWeek)
        }
        if hasGameDays {
            try container.encode(gameDays, forKey: .gameDays)
        }
        if hasByes {
            try container.encode(byes, forKey: .byes)
        }
        if hasGameGaps {
            try container.encode(gameGaps, forKey: .gameGaps)
        }
        if hasGameDayTimes {
            try container.encode(gameDayTimes, forKey: .gameDayTimes)
        }
        if hasGameDayLocations {
            try container.encode(gameDayLocations, forKey: .gameDayLocations)
        }
        if hasMatchupDurations {
            try container.encode(matchupDurations, forKey: .matchupDurations)
        }
        if hasLocationTimeExclusivities {
            try container.encode(locationTimeExclusivities, forKey: .locationTimeExclusivities)
        }
        if hasTravelDurations {
            try container.encode(travelDurations, forKey: .travelDurations)
        }
        if hasOpponents {
            try container.encode(opponents, forKey: .opponents)
        }
        if hasMaxSameOpponentMatchups {
            try container.encode(maxSameOpponentMatchups, forKey: .maxSameOpponentMatchups)
        }
    }

    public enum CodingKeys: CodingKey {
        case name
        case dayOfWeek
        case gameDays
        case byes
        case gameGaps
        case gameDayTimes
        case gameDayLocations
        case matchupDurations
        case locationTimeExclusivities
        case travelDurations
        case opponents
        case maxSameOpponentMatchups
    }
}

// MARK: General
extension LeagueDivision {
    public typealias IDValue = UInt32
}