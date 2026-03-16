
#if ProtobufCodable
extension LitLeagues_Leagues_EntryMatchupsPerGameDay: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameDayMatchups = try container.decode([DayIndex].self, forKey: .gameDayMatchups)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameDayMatchups, forKey: .gameDayMatchups)
    }

    enum CodingKeys: CodingKey {
        case gameDayMatchups
    }
}
#endif