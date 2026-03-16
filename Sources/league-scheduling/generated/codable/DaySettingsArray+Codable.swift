
#if ProtobufCodable
extension LitLeagues_Leagues_DaySettingsArray: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        days = try container.decode([LitLeagues_Leagues_DaySettings].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(days)
    }
}
#endif