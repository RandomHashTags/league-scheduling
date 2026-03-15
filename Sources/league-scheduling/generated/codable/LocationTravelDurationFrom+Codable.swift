
#if ProtobufCodable
extension LocationTravelDurationFrom: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        travelDurationTo = try container.decode([Double].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(travelDurationTo)
    }
}
#endif