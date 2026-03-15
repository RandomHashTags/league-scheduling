
import struct FoundationEssentials.Date
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleVolleyball: ScheduleTestsProtocol {
    @Test(.timeLimit(.minutes(1)))
    func scheduleVOLLEYBALL() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 4, 1, 7)
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
                StaticTime(hour: 7, minute: 30),
                StaticTime(hour: 8, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: divisions,
            entries: entries
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 36, data: data)
    }
}

extension ScheduleVolleyball {
    // MARK: 12GD | 3T | 1L | 1D | 5T | 1M
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MzU3MzM1MA==&arg3=NTA5Mzk=
    @Test
    func scheduleVolleyball_12GameDays3Times1Location5Teams1Matchup() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 3, 1, 5)
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
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: divisions,
            entries: entries
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 24, data: data)
    }
}

extension ScheduleVolleyball {
    // MARK: 12GD | 3T | 1L | 1D | 5T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MzU3MzM1MA==&arg3=NTA5Mzk=
    @Test
    func scheduleVolleyball_12GameDays3Times1Location5Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 3, 1, 5)
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
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: divisions,
            entries: entries
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 36, data: data)
    }
}

extension ScheduleVolleyball {
    // MARK: 12GD | 4T | 1L | 1D | 5T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MzU3MzM1MA==&arg3=NTA5Mzk=
    @Test
    func scheduleVolleyball_12GameDays4Times1Location5Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 4, 1, 5)
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
                StaticTime(hour: 7, minute: 30),
                StaticTime(hour: 8, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: divisions,
            entries: entries
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 48, data: data)
    }
}

extension ScheduleVolleyball {
    // MARK: 12GD | 3T | 2L | 1D | 5T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjk5NTUyNw==&arg3=NDI0OTE=
    @Test
    func scheduleVolleyball_12GameDays3Times2Location11Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 3, 2, 11)
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
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: divisions,
            entries: entries
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 72, data: data)
    }
}