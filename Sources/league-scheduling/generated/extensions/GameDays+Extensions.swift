
// MARK: Codable
extension LitLeagues_Leagues_GameDays: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        gameDayIndexes = try container.decode([LeagueDayIndex].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(gameDayIndexes)
    }
}

// MARK: Init
extension LitLeagues_Leagues_GameDays {
    public init(
        gameDayIndexes: [LeagueDayIndex]
    ) {
        self.gameDayIndexes = gameDayIndexes
    }
}