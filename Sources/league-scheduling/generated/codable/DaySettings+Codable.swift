
#if ProtobufCodable
extension DaySettings: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(GeneralSettings.self, forKey: .settings) {
            settings = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasSettings {
            try container.encode(settings, forKey: .settings)
        }
    }

    enum CodingKeys: CodingKey {
        case settings
    }
}
#endif