
#if ProtobufCodable
extension LeagueGameTimes: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        times = try container.decode([LeagueTimeIndex].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(times)
    }
}
#endif