
#if ProtobufCodable
extension Division: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .dayOfWeek) {
            self.dayOfWeek = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDays.self, forKey: .gameDays) {
            self.gameDays = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_Byes.self, forKey: .byes) {
            self.byes = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameGaps.self, forKey: .gameGaps) {
            self.gameGaps = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDayTimes.self, forKey: .gameDayTimes) {
            self.gameDayTimes = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDayLocations.self, forKey: .gameDayLocations) {
            self.gameDayLocations = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_DivisionMatchupDurations.self, forKey: .matchupDurations) {
            self.matchupDurations = v
        }
        if let v = try container.decodeIfPresent(LocationTimeExclusivities.self, forKey: .locationTimeExclusivities) {
            self.locationTimeExclusivities = v
        }
        if let v = try container.decodeIfPresent(LocationTravelDurations.self, forKey: .travelDurations) {
            self.travelDurations = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_DivisionOpponents.self, forKey: .opponents) {
            self.opponents = v
        }
        if let v = try container.decodeIfPresent(MaximumSameOpponentMatchupsCap.self, forKey: .maxSameOpponentMatchups) {
            self.maxSameOpponentMatchups = v
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

    enum CodingKeys: CodingKey {
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
#endif