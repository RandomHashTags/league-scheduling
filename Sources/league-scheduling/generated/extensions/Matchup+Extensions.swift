
// MARK: CustomStringConverible
extension LeagueMatchup: CustomStringConvertible {
    public var description: String {
        "T\(time)L\(location) \(away) @ \(home)"
    }
}

// MARK: General
extension LeagueMatchup {
    init(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        home: LeagueEntry.IDValue,
        away: LeagueEntry.IDValue
    ) {
        self.time = time
        self.location = location
        self.home = home
        self.away = away
    }

    var pair: LeagueMatchupPair {
        LeagueMatchupPair(team1: home, team2: away)
    }

    var slot: LeagueAvailableSlot {
       LeagueAvailableSlot(time: time, location: location)
    }
}