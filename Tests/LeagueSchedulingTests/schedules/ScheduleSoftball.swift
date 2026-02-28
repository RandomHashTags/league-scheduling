
@testable import LeagueScheduling
import StaticDateTimes
import Testing

// TODO: test https://secure.rec1.com/MN/owatonna-mn/leagues/publicLeague/1900749
// TODO: test https://secure.rec1.com/MN/owatonna-mn/leagues/publicLeague/2504395
@Suite
struct ScheduleSoftball: ScheduleTestsProtocol {
}

extension ScheduleSoftball {
    // MARK: 11GD | 4T | 3L | 1D | 12T
    // https://secure.rec1.com/MN/owatonna-mn/leagues/publicLeague/2301542
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_11GameDays4Times3Locations1Division12Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (11, 4, 3, 12)
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
        let data = await schedule.generate()
        try expectations(settings: schedule.settings, matchupsCount: 132, data: data)
    }
}

extension ScheduleSoftball {
    // MARK: 10GD | 4T | 4L | 1D | 16T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MzMwMjc3Mw==&arg3=NDY4Mjg=
    @Test(.timeLimit(.minutes(1)))
    func scheduleSoftball_10GameDays4Times4Locations1Division16Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (10, 4, 4, 16)
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
            prioritizeHomeAway: false,
            balanceHomeAway: true,
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
        let data = await schedule.generate()
        try expectations(settings: schedule.settings, matchupsCount: 160, data: data)
    }
}

extension ScheduleSoftball {
    // MARK: 10GD | 3T | 3L | 1D | 9T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjc0OTM0OQ==&arg3=Mzg1NDc=
    @Test(.timeLimit(.minutes(1)))
    func scheduleSoftball_10GameDays3Times3Locations1Division9Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (10, 3, 3, 9)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
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
        let data = await schedule.generate()
        try expectations(settings: schedule.settings, matchupsCount: 90, data: data)
    }
}