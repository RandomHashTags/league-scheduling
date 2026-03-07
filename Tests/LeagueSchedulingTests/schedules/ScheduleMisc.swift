
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleMisc: ScheduleTestsProtocol {
    // MARK: 5GD | 4T | 3L | 1D | 8T | 1M
    @Test(.timeLimit(.minutes(1)))
    func schedule5GameDays4Times3Locations1Division8Teams1Matchup() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (5, 4, 3, 8)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 5, minute: 30),
                StaticTime(hour: 8, minute: 0),
                StaticTime(hour: 10, minute: 30),
                StaticTime(hour: 13, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
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
        try expectations(
            settings: schedule,
            matchupsCount: 20,
            data: data
        )
    }
}

extension ScheduleMisc {
    // TODO: more complex division combinations need to support no game gap (which this test should use)
    // MARK: 5GD | 4T | 3L | 1D | 8T | 1M
    @Test(.timeLimit(.minutes(1)))
    func schedule5GameDays4Times3Locations2Divisions16Teams1Matchup() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (5, 4, 3, 16)
        var entryDivisions = [LeagueDivision.IDValue]()
        entryDivisions.append(contentsOf: [LeagueDivision.IDValue](repeating: 0, count: 8))
        entryDivisions.append(contentsOf: [LeagueDivision.IDValue](repeating: 1, count: 8))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 5, minute: 30),
                StaticTime(hour: 8, minute: 0),
                StaticTime(hour: 10, minute: 30),
                StaticTime(hour: 13, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, 8)),
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, 8))
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
        try expectations(
            settings: schedule,
            matchupsCount: 40,
            data: data
        )
    }
}

extension ScheduleMisc {
    // MARK: Kids Basketball
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjUwOTgxMA==&arg3=MzQ1OTg=
    @Test(.timeLimit(.minutes(1)))
    func schedule6GameDays2Times2Locations1Division6Teams1Matchup() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (6, 2, 2, 6)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 8, minute: 30),
                StaticTime(hour: 9, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1), // TODO: fails if we try b2b
            divisions: [
                try Self.getDivision(dayOfWeek: .saturday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
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
        try expectations(
            settings: schedule,
            matchupsCount: 18,
            data: data
        )
    }
}

extension ScheduleMisc {
    // MARK: 8GD | 8T | 3L | 1D | 9T | 4M
    @Test(.timeLimit(.minutes(1)))
    func schedule8GameDays8Times3Locations1Division9Teams4Matchups() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 4
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (8, 8, 3, 9)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 16, minute: 30),
                StaticTime(hour: 17, minute: 0),
                StaticTime(hour: 17, minute: 30),
                StaticTime(hour: 18, minute: 0),
                
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
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
        try expectations(
            settings: schedule,
            matchupsCount: 144,
            data: data
        )
    }
}

extension ScheduleMisc {
    // MARK: 10GD | 4T | 5L | 2D | 20T | 2M
    @Test(.timeLimit(.minutes(1)))
    func schedule10GameDays4Times5Locations2Divisions20Teams2Matchups() async throws {
        let schedule = try Self.schedule10GameDays4Times5Locations2Divisions20Teams2Matchups()
        let data = await LeagueSchedule.generate(schedule)
        try expectations(
            settings: schedule,
            matchupsCount: 200,
            data: data
        )
    }

    static func schedule10GameDays4Times5Locations2Divisions20Teams2Matchups() throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (10, 4, 5, 20)
        var entryDivisions = [LeagueDivision.IDValue]()
        entryDivisions.append(contentsOf: [LeagueDivision.IDValue](repeating: 0, count: 10))
        entryDivisions.append(contentsOf: [LeagueDivision.IDValue](repeating: 1, count: 10))
        return getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 16, minute: 30),
                StaticTime(hour: 17, minute: 0),
                StaticTime(hour: 17, minute: 30),
                StaticTime(hour: 18, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, 10)),
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, 10))
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