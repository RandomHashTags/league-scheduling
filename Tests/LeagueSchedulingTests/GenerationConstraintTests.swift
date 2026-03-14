
@testable import LeagueScheduling
import Testing

struct GenerationConstraintTests: ScheduleExpectations {
    // TODO: if we improve the generation logic, how do we properly test? For now we can use a fairly complex schedule

    @Test(.timeLimit(.minutes(1)))
    func generationConstraint1Second() async throws {
        var constraints = GenerationConstraints.default
        constraints.timeoutDelay = 1
        let schedule = try ScheduleBeanBagToss.scheduleBeanBagToss_10GameDays4Time8Locations1Division21Teams(constraints: constraints)
        let now = ContinuousClock.now
        let data = await schedule.generate()
        let elapsed = ContinuousClock.now - now
        try #require(elapsed < .seconds(2))
        if let e = data.error {
            #expect(e.starts(with: "Failed to build schedule within provided time limit;"))
        } else {
            try expectations(
                settings: schedule.settings,
                matchupsCount: 210,
                data: data
            )
        }
    }
}