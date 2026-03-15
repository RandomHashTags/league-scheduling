
#if ProtobufCodable
extension LeagueLocationTravelDurations: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        locations = try container.decode([LeagueLocationTravelDurationFrom].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(locations)
    }
}
#endif