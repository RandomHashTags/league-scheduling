
// MARK: CustomStringConvertible
extension MatchupPair: CustomStringConvertible {
    public var description: String {
        "\(team2) @ \(team1)"
    }
}

// MARK: Hashable
extension MatchupPair: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(team1)
        hasher.combine(team2)
    }
}

// MARK: Initializer
extension MatchupPair {
    init(team1: Entry.IDValue, team2: Entry.IDValue) {
        self.team1 = team1
        self.team2 = team2
    }
}