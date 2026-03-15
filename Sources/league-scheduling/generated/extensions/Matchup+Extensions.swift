
// MARK: CustomStringConverible
extension Matchup: CustomStringConvertible {
    public var description: String {
        "T\(time)L\(location) \(away) @ \(home)"
    }
}

// MARK: General
extension Matchup {
    init(
        time: TimeIndex,
        location: LocationIndex,
        home: Entry.IDValue,
        away: Entry.IDValue
    ) {
        self.time = time
        self.location = location
        self.home = home
        self.away = away
    }

    var pair: MatchupPair {
        MatchupPair(team1: home, team2: away)
    }

    var slot: AvailableSlot {
       AvailableSlot(time: time, location: location)
    }
}