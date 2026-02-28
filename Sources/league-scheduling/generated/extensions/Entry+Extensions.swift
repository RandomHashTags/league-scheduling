

// MARK: Codable
extension LeagueEntry: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        }
        division = try container.decode(LeagueDivision.IDValue.self, forKey: .division)
        if let gameDays = try container.decodeIfPresent(LitLeagues_Leagues_GameDays.self, forKey: .gameDays) {
            self.gameDays = gameDays
        }
        if let gameDayTimes = try container.decodeIfPresent(LitLeagues_Leagues_GameDayTimes.self, forKey: .gameDayTimes) {
            self.gameDayTimes = gameDayTimes
        }
        if let gameDayLocations = try container.decodeIfPresent(LitLeagues_Leagues_GameDayLocations.self, forKey: .gameDayLocations) {
            self.gameDayLocations = gameDayLocations
        }
        if let homeLocations = try container.decodeIfPresent(LitLeagues_Leagues_EntryHomeLocations.self, forKey: .homeLocations) {
            self.homeLocations = homeLocations
        }
        if let byes = try container.decodeIfPresent(LitLeagues_Leagues_Byes.self, forKey: .byes) {
            self.byes = byes
        }
        if let matchupsPerGameDay = try container.decodeIfPresent([LeagueEntryMatchupsPerGameDay].self, forKey: .gameDayMatchups) {
            self.matchupsPerGameDay = .init(gameDayMatchups: matchupsPerGameDay)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasName {
            try container.encode(name, forKey: .name)
        }
        try container.encode(division, forKey: .division)
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

    public enum CodingKeys: CodingKey {
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

// MARK: General
extension LeagueEntry {
    public typealias IDValue = UInt32

    public init(
        division: LeagueDivision.IDValue,
        gameDays: LitLeagues_Leagues_GameDays?,
        gameDayTimes: LitLeagues_Leagues_GameDayTimes?,
        gameDayLocations: LitLeagues_Leagues_GameDayLocations?,
        homeLocations: LitLeagues_Leagues_EntryHomeLocations?,
        byes: LitLeagues_Leagues_Byes?,
        matchupsPerGameDay: [LeagueEntryMatchupsPerGameDay]? = nil
    ) {
        self.division = division
        if let gameDays {
            self.gameDays = gameDays
        }
        if let gameDayTimes {
            self.gameDayTimes = gameDayTimes
        }
        if let gameDayLocations {
            self.gameDayLocations = gameDayLocations
        }
        if let homeLocations {
            self.homeLocations = homeLocations
        }
        if let byes {
            self.byes = byes
        }
        if let matchupsPerGameDay {
            self.matchupsPerGameDay = .init(gameDayMatchups: matchupsPerGameDay)
        }
    }
}