
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleFootball: ScheduleTestsProtocol {
}

extension ScheduleFootball {
    // MARK: 10GD | 1T | 3L | 1D | 6T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjUwNTQwNw==&arg3=MzI3Nzg=
    @Test(.timeLimit(.minutes(1)))
    func scheduleFootball_10GameDays1Time3Locations1Division6Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (10, 1, 3, 6)
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
        try expectations(settings: schedule.settings, matchupsCount: 30, data: data)
    }
}