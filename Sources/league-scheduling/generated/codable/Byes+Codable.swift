
#if ProtobufCodable
extension LitLeagues_Leagues_Byes: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        byes = try container.decode([DayIndex].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(byes)
    }
}
#endif