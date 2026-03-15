
#if ProtobufCodable
extension Matchup: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(TimeIndex.self, forKey: .time)
        location = try container.decode(LocationIndex.self, forKey: .location)
        home = try container.decode(Entry.IDValue.self, forKey: .home)
        away = try container.decode(Entry.IDValue.self, forKey: .away)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(location, forKey: .location)
        try container.encode(home, forKey: .home)
        try container.encode(away, forKey: .away)
    }

    enum CodingKeys: CodingKey {
        case time
        case location
        case home
        case away
    }
}
#endif