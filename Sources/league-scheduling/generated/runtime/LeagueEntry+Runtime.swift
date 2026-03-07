
extension LeagueEntry {
    func runtime(
        id: IDValue,
        division: LeagueDivision.IDValue,
        defaultGameDays: Set<LeagueDayIndex>,
        defaultByes: Set<LeagueDayIndex>,
        defaultGameTimes: [BitSet64<LeagueTimeIndex>],
        defaultGameLocations: [BitSet64<LeagueLocationIndex>]
    ) -> Runtime {
        return .init(
            id: id,
            division: division,
            protobuf: self,
            defaultGameDays: defaultGameDays,
            defaultByes: defaultByes,
            defaultGameTimes: defaultGameTimes,
            defaultGameLocations: defaultGameLocations
        )
    }

    /// For optimal runtime performance.
    struct Runtime: Sendable {
        /// ID associated with this entry.
        let id:LeagueEntry.IDValue

        /// Division id this entry is in.
        let division:LeagueDivision.IDValue

        /// Game days this entry can play on.
        let gameDays:Set<LeagueDayIndex>

        /// Times this entry can play at for a specific day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `Set<LeagueTimeIndex>`]
        let gameTimes:[BitSet64<LeagueTimeIndex>]

        /// Locations this entry can play at for a specific day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `Set<LeagueLocationIndex>`]
        let gameLocations:[BitSet64<LeagueLocationIndex>]

        /// Home locations for this entry.
        let homeLocations:BitSet64<LeagueLocationIndex>

        /// Day indexes where this entry doesn't play due to being on a bye week.
        let byes:Set<LeagueDayIndex>

        let matchupsPerGameDay:LitLeagues_Leagues_EntryMatchupsPerGameDay?

        init(
            id: LeagueEntry.IDValue,
            division: LeagueDivision.IDValue,
            protobuf: LeagueEntry,
            defaultGameDays: Set<LeagueDayIndex>,
            defaultByes: Set<LeagueDayIndex>,
            defaultGameTimes: [BitSet64<LeagueTimeIndex>],
            defaultGameLocations: [BitSet64<LeagueLocationIndex>]
        ) {
            self.id = id
            self.division = division
            gameDays = protobuf.hasGameDays ? Set(protobuf.gameDays.gameDayIndexes) : defaultGameDays
            gameTimes = protobuf.hasGameDayTimes ? protobuf.gameDayTimes.times.map({ .init($0.times) }) : defaultGameTimes
            gameLocations = protobuf.hasGameDayLocations ? protobuf.gameDayLocations.locations.map({ .init($0.locations) }) : defaultGameLocations
            homeLocations = protobuf.hasHomeLocations ? .init(protobuf.homeLocations.homeLocations) : .init()
            byes = protobuf.hasByes ? Set(protobuf.byes.byes) : defaultByes
            matchupsPerGameDay = protobuf.hasMatchupsPerGameDay ? protobuf.matchupsPerGameDay : nil
        }

        init(
            id: LeagueEntry.IDValue,
            division: LeagueDivision.IDValue,
            gameDays: Set<LeagueDayIndex>,
            gameTimes: [BitSet64<LeagueTimeIndex>],
            gameLocations: [BitSet64<LeagueLocationIndex>],
            homeLocations: BitSet64<LeagueLocationIndex>,
            byes: Set<LeagueDayIndex>,
            matchupsPerGameDay: LitLeagues_Leagues_EntryMatchupsPerGameDay?
        ) {
            self.id = id
            self.division = division
            self.gameDays = gameDays
            self.gameTimes = gameTimes
            self.gameLocations = gameLocations
            self.homeLocations = homeLocations
            self.byes = byes
            self.matchupsPerGameDay = matchupsPerGameDay
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        /// - Returns: Maximum number of matchups this entry can play on the given day index.
        func maxMatchupsForGameDay(
            day: LeagueDayIndex,
            fallback: LeagueEntryMatchupsPerGameDay
        ) -> LeagueEntryMatchupsPerGameDay {
            return matchupsPerGameDay?.gameDayMatchups[uncheckedPositive: day] ?? fallback
        }
    }
}