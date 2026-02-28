
// MARK: Codable
extension LeagueDaySettings: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(LeagueGeneralSettings.self, forKey: .settings) {
            settings = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasSettings {
            try container.encode(settings, forKey: .settings)
        }
    }

    public enum CodingKeys: CodingKey {
        case settings
    }
}