
#if ProtobufCodable
extension LitLeagues_Leagues_GameGaps: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        gameGaps = try container.decode([String].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(gameGaps)
    }
}
#endif