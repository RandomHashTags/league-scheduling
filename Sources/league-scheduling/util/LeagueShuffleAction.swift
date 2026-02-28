
public struct LeagueShuffleAction: Sendable {
    public let day:LeagueDayIndex
    public let from:LeagueAvailableSlot
    public let to:LeagueAvailableSlot
    public let pair:LeagueMatchupPair
}

// MARK: Codable
extension LeagueShuffleAction: Codable {
}