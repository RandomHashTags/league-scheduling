
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleSameLocationIfB2B: ScheduleTestsProtocol {

    @Test
    func scheduleSameLocationIfB2B_8GameDays3Times3Locations1Division9Teams() async throws {
        let schedule = try Self.scheduleSameLocationIfB2B_8GameDays3Times3Locations1Division9Teams()
        let data = await schedule.generate()
        try expectations(
            settings: schedule,
            matchupsCount: 72,
            data: data
        )
    }
    static func scheduleSameLocationIfB2B_8GameDays3Times3Locations1Division9Teams() throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (8, 3, 3, 9)
        let entries = getEntries(
            divisions: [Division.IDValue](repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        return getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 6, minute: 30),
                StaticTime(hour: 7, minute: 0),
                StaticTime(hour: 7, minute: 30)
            ],
            locations: locations,
            optimizeTimes: false,
            prioritizeHomeAway: false,
            sameLocationIfB2B: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: entries
        )
    }
}

extension ScheduleSameLocationIfB2B {
    @Test
    func scheduleSameLocationIfB2B_12GameDays3Times1Locations1Division5Teams() async throws {
        let schedule = try Self.scheduleSameLocationIfB2B_12GameDays3Times1Locations1Division5Teams()
        let data = await schedule.generate()
        try expectations(
            settings: schedule,
            matchupsCount: 30,
            data: data
        )
    }
    static func scheduleSameLocationIfB2B_12GameDays3Times1Locations1Division5Teams() throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (12, 3, 1, 5)
        let entries = getEntries(
            divisions: [Division.IDValue](repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        return getSchedule(
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
            optimizeTimes: false,
            prioritizeHomeAway: false,
            sameLocationIfB2B: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: entries
        )
    }
}

extension ScheduleSameLocationIfB2B {
    @Test
    func scheduleSameLocationIfB2B_10GameDays4Times4Locations1Division16Teams() async throws {
        let schedule = try Self.scheduleSameLocationIfB2B_10GameDays4Times4Locations1Division16Teams()
        let data = await schedule.generate()
        try expectations(
            settings: schedule,
            matchupsCount: 160,
            data: data
        )
    }
    static func scheduleSameLocationIfB2B_10GameDays4Times4Locations1Division16Teams() throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 4, 16)
        let entries = getEntries(
            divisions: [Division.IDValue](repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        return getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            maximumPlayableMatchups: .init(repeating: 20, count: teams),
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 6, minute: 30),
                StaticTime(hour: 7, minute: 0),
                StaticTime(hour: 7, minute: 30),
                StaticTime(hour: 8, minute: 0)
            ],
            locations: locations,
            optimizeTimes: false,
            prioritizeEarlierTimes: true,
            prioritizeHomeAway: false,
            sameLocationIfB2B: true,
            redistributionSettings: .init(),
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: entries
        )
    }
}