
#if ProtobufCodable
extension LitLeagues_Leagues_UInt32Array: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        array = try container.decode([UInt32].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(array)
    }
}
#endif