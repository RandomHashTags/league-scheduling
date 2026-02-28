
// MARK: Codable
extension LeagueMatchup: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(LeagueTimeIndex.self, forKey: .time)
        location = try container.decode(LeagueLocationIndex.self, forKey: .location)
        home = try container.decode(LeagueEntry.IDValue.self, forKey: .home)
        away = try container.decode(LeagueEntry.IDValue.self, forKey: .away)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(location, forKey: .location)
        try container.encode(home, forKey: .home)
        try container.encode(away, forKey: .away)
    }

    public enum CodingKeys: CodingKey {
        case time
        case location
        case home
        case away
    }
}

// MARK: CustomStringConverible
extension LeagueMatchup: CustomStringConvertible {
    public var description: String {
        "T\(time)L\(location) \(away) @ \(home)"
    }
}

// MARK: General
extension LeagueMatchup {
    public init(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        home: LeagueEntry.IDValue,
        away: LeagueEntry.IDValue
    ) {
        self.time = time
        self.location = location
        self.home = home
        self.away = away
    }

    public var pair: LeagueMatchupPair {
        LeagueMatchupPair(team1: home, team2: away)
    }

    public var slot: LeagueAvailableSlot {
       LeagueAvailableSlot(time: time, location: location)
    }
}