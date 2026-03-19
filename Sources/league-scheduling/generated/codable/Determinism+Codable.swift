
#if ProtobufCodable
extension LitLeagues_Leagues_Determinism: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .technique) {
            technique = v
        }
        if let v = try container.decodeIfPresent(UInt64.self, forKey: .seed) {
            seed = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasTechnique {
            try container.encode(technique, forKey: .technique)
        }
        if hasSeed {
            try container.encode(seed, forKey: .seed)
        }
    }

    enum CodingKeys: CodingKey {
        case technique
        case seed
    }
}
#endif