
#if ProtobufCodable
extension LeagueEntry: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = v
        }
        if let v = try container.decodeIfPresent(LeagueDivision.IDValue.self, forKey: .division) {
            division = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDays.self, forKey: .gameDays) {
            self.gameDays = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDayTimes.self, forKey: .gameDayTimes) {
            self.gameDayTimes = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_GameDayLocations.self, forKey: .gameDayLocations) {
            self.gameDayLocations = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_EntryHomeLocations.self, forKey: .homeLocations) {
            self.homeLocations = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_Byes.self, forKey: .byes) {
            self.byes = v
        }
        if let v = try container.decodeIfPresent([LeagueEntryMatchupsPerGameDay].self, forKey: .gameDayMatchups) {
            self.matchupsPerGameDay = .init(gameDayMatchups: v)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasName {
            try container.encode(name, forKey: .name)
        }
        if hasDivision {
            try container.encode(division, forKey: .division)
        }
        if hasGameDays {
            try container.encode(gameDays, forKey: .gameDays)
        }
        if hasGameDayTimes {
            try container.encode(gameDayTimes, forKey: .gameDayTimes)
        }
        if hasGameDayLocations {
            try container.encode(gameDayLocations, forKey: .gameDayLocations)
        }
        if hasHomeLocations {
            try container.encode(homeLocations.homeLocations, forKey: .homeLocations)
        }
        if hasByes {
            try container.encode(byes.byes, forKey: .byes)
        }
        if hasMatchupsPerGameDay {
            try container.encode(matchupsPerGameDay.gameDayMatchups, forKey: .gameDayMatchups)
        }
    }

    enum CodingKeys: CodingKey {
        case name
        case division
        case gameDays
        case gameDayTimes
        case gameDayLocations
        case homeLocations
        case byes
        case gameDayMatchups
    }
}
#endif