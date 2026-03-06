
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleTball: ScheduleTestsProtocol {
}

extension ScheduleTball {
    // MARK: 4GD | 3T | 1L | 1D | 6T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjc0OTI3NQ==&arg3=Mzg5OTk=
    @Test(.timeLimit(.minutes(1)))
    func scheduleTball_4GameDays3Times1Location1Division6Teams() async throws {
        let maxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay = 1
        let (gameDays, times, locations, teams):(LeagueDayIndex, LeagueTimeIndex, LeagueLocationIndex, Int) = (4, 3, 1, 6)
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
        let data = await LeagueSchedule.generate(schedule)
        try expectations(settings: schedule, matchupsCount: 12, data: data)
    }
}