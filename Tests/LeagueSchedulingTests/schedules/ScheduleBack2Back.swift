
import struct FoundationEssentials.Date
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleBack2Back: ScheduleTestsProtocol {
    // MARK: 2 divisions | 12/12
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_11GameDays4Times6Locations2Divisions24TeamsEvenSplit() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (11, 4, 6, 24)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 12))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 12))
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
            prioritizeEarlierTimes: false,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 264, data: data)
    }
}

extension ScheduleBack2Back {
    // MARK: 2 divisions | 14/10
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_11GameDays4Times6Locations2Divisions24Teams14_10() async throws {
        let schedule = try Self.scheduleB2B_11GameDays4Times6Locations2Divisions24Teams14_10()
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 264, data: data)
    }
    static func scheduleB2B_11GameDays4Times6Locations2Divisions24Teams14_10() throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (11, 4, 6, 24)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 14))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 10))
        return Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15),
                StaticTime(hour: 21, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeEarlierTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            balanceTimeStrictness: .relaxed,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .sunday, values: (gameDays, maxEntryMatchupsPerGameDay, 14)),
                try Self.getDivision(dayOfWeek: .sunday, values: (gameDays, maxEntryMatchupsPerGameDay, 10))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
    }
}

extension ScheduleBack2Back {
    // MARK: 2 divisions | 11/10
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_10GameDays4Times6Locations2Divisions21Teams11_10() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 5, 21)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 11))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 10))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15),
                StaticTime(hour: 21, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeEarlierTimes: true,
            prioritizeHomeAway: true,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .sunday, values: (gameDays, maxEntryMatchupsPerGameDay, 11)),
                try Self.getDivision(dayOfWeek: .sunday, values: (gameDays, maxEntryMatchupsPerGameDay, 10))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 200, data: data)
    }
}