
#if ProtobufCodable
extension MatchupPair: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        team1 = try container.decode(Entry.IDValue.self, forKey: .team1)
        team2 = try container.decode(Entry.IDValue.self, forKey: .team2)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team1, forKey: .team1)
        try container.encode(team2, forKey: .team2)
    }

    enum CodingKeys: CodingKey {
        case team1
        case team2
    }
}
#endif