
extension Entry {
    typealias IDValue = UInt32

    init(
        division: Division.IDValue,
        gameDays: LitLeagues_Leagues_GameDays?,
        gameDayTimes: LitLeagues_Leagues_GameDayTimes?,
        gameDayLocations: LitLeagues_Leagues_GameDayLocations?,
        homeLocations: LitLeagues_Leagues_EntryHomeLocations?,
        byes: LitLeagues_Leagues_Byes?,
        matchupsPerGameDay: [EntryMatchupsPerGameDay]? = nil
    ) {
        self.division = division
        if let gameDays {
            self.gameDays = gameDays
        }
        if let gameDayTimes {
            self.gameDayTimes = gameDayTimes
        }
        if let gameDayLocations {
            self.gameDayLocations = gameDayLocations
        }
        if let homeLocations {
            self.homeLocations = homeLocations
        }
        if let byes {
            self.byes = byes
        }
        if let matchupsPerGameDay {
            self.matchupsPerGameDay = .init(gameDayMatchups: matchupsPerGameDay)
        }
    }
}