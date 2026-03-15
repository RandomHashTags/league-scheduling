
#if ProtobufCodable
extension LeagueRequestPayload: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(String.self, forKey: .starts) {
            starts = v
        }
        gameDays = try container.decode(LeagueDayIndex.self, forKey: .gameDays)
        settings = try container.decode(LeagueGeneralSettings.self, forKey: .settings)
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_DaySettingsArray.self, forKey: .individualDaySettings) {
            individualDaySettings = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_Divisions.self, forKey: .divisions) {
            divisions = v
        }
        entries = try container.decode([LeagueEntry].self, forKey: .teams)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasStarts {
            try container.encode(starts, forKey: .starts)
        }
        try container.encode(gameDays, forKey: .gameDays)
        try container.encode(settings, forKey: .settings)
        if hasIndividualDaySettings {
            try container.encode(individualDaySettings, forKey: .individualDaySettings)
        }
        if hasDivisions {
            try container.encode(divisions, forKey: .divisions)
        }
        try container.encode(entries, forKey: .teams)
    }

    enum CodingKeys: CodingKey {
        case starts
        case gameDays
        case settings
        case individualDaySettings
        case divisions
        case teams
    }
}
#endif