
#if ProtobufCodable
extension LitLeagues_Leagues_EntryHomeLocations: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        homeLocations = try container.decode([LeagueLocationIndex].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(homeLocations)
    }
}
#endif