
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleBaseball: ScheduleTestsProtocol {
}

extension ScheduleBaseball {
    // MARK: 7GD | 2T | 2L | 1D | 8T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjc0OTMzNg==&arg3=MzU2NzQ=
    @Test(.timeLimit(.minutes(1)))
    func scheduleBaseball_7GameDays2Times2Locations1Division8Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (7, 2, 2, 8)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15)
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
        try expectations(settings: schedule, matchupsCount: 28, data: data)
    }
}

extension ScheduleBaseball {
    // MARK: 8GD | 2T | 2L | 1D | 8T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjMwMDc5OA==&arg3=MzA2OTA=
    @Test(.timeLimit(.minutes(1)))
    func scheduleBaseball_8GameDays2Times2Locations1Division8Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (8, 2, 2, 8)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 17, minute: 30),
                StaticTime(hour: 19, minute: 0)
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
        try expectations(settings: schedule, matchupsCount: 32, data: data)
    }
}