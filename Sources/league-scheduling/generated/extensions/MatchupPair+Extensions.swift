
// MARK: Codable
extension LeagueMatchupPair: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        team1 = try container.decode(LeagueEntry.IDValue.self, forKey: .team1)
        team2 = try container.decode(LeagueEntry.IDValue.self, forKey: .team2)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team1, forKey: .team1)
        try container.encode(team2, forKey: .team2)
    }

    enum CodingKeys: CodingKey {
        case team1
        case team2
    }
}

// MARK: CustomStringConvertible
extension LeagueMatchupPair: CustomStringConvertible {
    public var description: String {
        "\(team2) @ \(team1)"
    }
}

// MARK: Hashable
extension LeagueMatchupPair: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(team1)
        hasher.combine(team2)
    }
}

// MARK: Initializer
extension LeagueMatchupPair {
    init(team1: LeagueEntry.IDValue, team2: LeagueEntry.IDValue) {
        self.team1 = team1
        self.team2 = team2
    }
}