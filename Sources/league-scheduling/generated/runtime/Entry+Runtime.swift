
extension Entry {
    func runtime(
        id: IDValue,
        division: Division.IDValue,
        defaultGameDays: Set<DayIndex>,
        defaultByes: Set<DayIndex>,
        defaultGameTimes: [Set<TimeIndex>],
        defaultGameLocations: [Set<LocationIndex>]
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
        let id:Entry.IDValue

        /// Division id this entry is in.
        let division:Division.IDValue

        /// Game days this entry can play on.
        let gameDays:Set<DayIndex>

        /// Times this entry can play at for a specific day index.
        /// 
        /// - Usage: [`DayIndex`: `Set<TimeIndex>`]
        let gameTimes:[Set<TimeIndex>]

        /// Locations this entry can play at for a specific day index.
        /// 
        /// - Usage: [`DayIndex`: `Set<LocationIndex>`]
        let gameLocations:[Set<LocationIndex>]

        /// Home locations for this entry.
        let homeLocations:Set<LocationIndex>

        /// Day indexes where this entry doesn't play due to being on a bye week.
        let byes:Set<DayIndex>

        let matchupsPerGameDay:LitLeagues_Leagues_EntryMatchupsPerGameDay?

        init(
            id: Entry.IDValue,
            division: Division.IDValue,
            protobuf: Entry,
            defaultGameDays: Set<DayIndex>,
            defaultByes: Set<DayIndex>,
            defaultGameTimes: [Set<TimeIndex>],
            defaultGameLocations: [Set<LocationIndex>]
        ) {
            self.id = id
            self.division = division
            gameDays = protobuf.hasGameDays ? Set(protobuf.gameDays.gameDayIndexes) : defaultGameDays
            gameTimes = protobuf.hasGameDayTimes ? protobuf.gameDayTimes.times.map({ Set($0.times) }) : defaultGameTimes
            gameLocations = protobuf.hasGameDayLocations ? protobuf.gameDayLocations.locations.map({ Set($0.locations) }) : defaultGameLocations
            homeLocations = protobuf.hasHomeLocations ? Set(protobuf.homeLocations.homeLocations) : []
            byes = protobuf.hasByes ? Set(protobuf.byes.byes) : defaultByes
            matchupsPerGameDay = protobuf.hasMatchupsPerGameDay ? protobuf.matchupsPerGameDay : nil
        }

        init(
            id: Entry.IDValue,
            division: Division.IDValue,
            gameDays: Set<DayIndex>,
            gameTimes: [Set<TimeIndex>],
            gameLocations: [Set<LocationIndex>],
            homeLocations: Set<LocationIndex>,
            byes: Set<DayIndex>,
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

        /// - Returns: Maximum number of matchups this entry can play on the given day index.
        func maxMatchupsForGameDay(
            day: DayIndex,
            fallback: EntryMatchupsPerGameDay
        ) -> EntryMatchupsPerGameDay {
            return matchupsPerGameDay?.gameDayMatchups[uncheckedPositive: day] ?? fallback
        }
    }
}