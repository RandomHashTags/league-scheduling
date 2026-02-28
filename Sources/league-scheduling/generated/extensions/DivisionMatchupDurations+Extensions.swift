
// MARK: Codable
extension LitLeagues_Leagues_DivisionMatchupDurations: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        durations = try container.decode([Double].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(durations)
    }
}