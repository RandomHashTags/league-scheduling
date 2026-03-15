
#if ProtobufCodable

import StaticDateTimes

extension LitLeagues_Leagues_StaticTimes: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        times = try container.decode([StaticTime].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(times)
    }
}
#endif