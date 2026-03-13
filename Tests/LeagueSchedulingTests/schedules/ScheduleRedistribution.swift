
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleRedistribution: ScheduleTestsProtocol {
}

extension ScheduleRedistribution {
    // MARK: 11GD | 3T | 1L | 1D | 5T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MzU3MzM1MA==&arg3=NTA5Mzk=
    @Test
    func scheduleRedistribution_11GameDays3Times1Location5Teams12MaxMatchupsPerEntry() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (11, 3, 1, 5)
        let entries = Self.getEntries(
            divisions: .init(repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        let divisions = [
            try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
        ]
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            maximumPlayableMatchups: .init(repeating: 12, count: teams),
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 6, minute: 30),
                StaticTime(hour: 7, minute: 0),
                StaticTime(hour: 7, minute: 30)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            redistributionSettings: .init(
                minMatchupsRequired: 2,
                maxMovableMatchups: 3
            ),
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: divisions,
            entries: entries
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 30, data: data)
    }
}

extension ScheduleRedistribution {
    // MARK: 11GD | 3T | 1L | 1D | 7T
    @Test
    func scheduleRedistribution_11GameDays3Times1Location7Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (11, 3, 1, 7)
        let entries = Self.getEntries(
            divisions: .init(repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        let divisions = [
            try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
        ]
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 6, minute: 30),
                StaticTime(hour: 7, minute: 0),
                StaticTime(hour: 7, minute: 30)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            redistributionSettings: .init(
                minMatchupsRequired: 2,
                maxMovableMatchups: 3
            ),
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: divisions,
            entries: entries
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 33, data: data)
    }
}

extension ScheduleRedistribution {
    // MARK: 6GD | 4T | 4L | 1D | 15T
    // https://secure.rec1.com/MN/owatonna-mn/leagues/publicLeague/2301542
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjk3NjYzNA==&arg3=NDEwMjA=
    @Test(.timeLimit(.minutes(1)))
    func scheduleRedistribution_6GameDays4Times4Locations1Division15Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (6, 4, 4, 15)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            maximumPlayableMatchups: .init(repeating: 10, count: teams),
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15),
                StaticTime(hour: 21, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            redistributionSettings: .init(
                minMatchupsRequired: 2,
                maxMovableMatchups: 3
            ),
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: Self.getEntries(
                divisions: .init(repeating: 0, count: teams),
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 75, data: data)
    }
}

extension ScheduleRedistribution {
    // MARK: 10GD | 4T | 4L | 1D | 9T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjUwNTQwNg%3D%3D&arg3=MzI2MjA%3D
    @Test(.timeLimit(.minutes(1)))
    func scheduleRedistribution_10GameDays4Times4Locations1Division9Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (10, 4, 4, 9)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            maximumPlayableMatchups: .init(repeating: 14, count: teams),
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15),
                StaticTime(hour: 21, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            redistributionSettings: .init(
                minMatchupsRequired: 6,
                maxMovableMatchups: 6
            ),
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: Self.getEntries(
                divisions: .init(repeating: 0, count: teams),
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 60, data: data)
    }
}