
// MARK: Codable
extension LitLeagues_Leagues_GameDayLocations: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        locations = try container.decode([LeagueGameLocations].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(locations)
    }
}

// MARK: Init
extension LitLeagues_Leagues_GameDayLocations {
    public init(
        locations: [LeagueGameLocations]
    ) {
        self.locations = locations
    }
}