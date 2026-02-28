
// MARK: Codable
extension LeagueBalanceStrictness: Codable {
}

// MARK: General
extension LeagueBalanceStrictness {
    public init?(rawValue: String) {
        switch rawValue {
        case "lenient", "LENIENT": self = .lenient
        case "relaxed", "RELAXED": self = .relaxed
        case "normal", "NORMAL": self = .normal
        case "very", "VERY": self = .very
        default: return nil
        }
    }
}