
// MARK: Codable
extension LitLeagues_Leagues_RedistributionSettings: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .minMatchupsRequired) {
            minMatchupsRequired = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .maxMovableMatchups) {
            maxMovableMatchups = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasMinMatchupsRequired {
            try container.encode(minMatchupsRequired, forKey: .minMatchupsRequired)
        }
        if hasMaxMovableMatchups {
            try container.encode(maxMovableMatchups, forKey: .maxMovableMatchups)
        }
    }

    enum CodingKeys: CodingKey {
        case minMatchupsRequired
        case maxMovableMatchups
    }
}

// MARK: Init
extension LitLeagues_Leagues_RedistributionSettings {
    init(
        minMatchupsRequired: UInt32? = nil,
        maxMovableMatchups: UInt32? = nil
    ) {
        if let m = minMatchupsRequired {
            self.minMatchupsRequired = m
        }
        if let m = maxMovableMatchups {
            self.maxMovableMatchups = m
        }
    }
}