
// MARK: Codable
extension LitLeagues_Leagues_EntryMatchupsPerGameDay: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameDayMatchups = try container.decode([LeagueDayIndex].self, forKey: .gameDayMatchups)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameDayMatchups, forKey: .gameDayMatchups)
    }

    enum CodingKeys: CodingKey {
        case gameDayMatchups
    }
}

// MARK: Initializer
extension LitLeagues_Leagues_EntryMatchupsPerGameDay {
    init(gameDayMatchups: [LeagueEntryMatchupsPerGameDay]) {
        self.gameDayMatchups = gameDayMatchups
    }
}