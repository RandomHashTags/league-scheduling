
#if ProtobufCodable
extension LitLeagues_Leagues_Divisions: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        divisions = try container.decode([Division].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(divisions)
    }
}
#endif