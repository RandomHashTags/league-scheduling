
// MARK: CustomStringConvertible
extension LeagueMatchupPair: CustomStringConvertible {
    public var description: String {
        "\(team2) @ \(team1)"
    }
}

// MARK: Hashable
extension LeagueMatchupPair: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(team1)
        hasher.combine(team2)
    }
}

// MARK: Initializer
extension LeagueMatchupPair {
    init(team1: LeagueEntry.IDValue, team2: LeagueEntry.IDValue) {
        self.team1 = team1
        self.team2 = team2
    }
}