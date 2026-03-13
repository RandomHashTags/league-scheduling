
@testable import LeagueScheduling
import Testing

struct DayExpectations<Config: ScheduleConfiguration>: ScheduleTestsProtocol {
    let b2bMatchupsAtDifferentLocations:Set<ValidLeagueMatchup>

    func expectations(_ settings: LeagueGeneralSettings.Runtime<Config>) {
        if settings.sameLocationIfB2B {
            sameLocationIfB2B()
        }
    }
}

// MARK: Same location if b2b
extension DayExpectations {
    private func sameLocationIfB2B() {
        #expect(b2bMatchupsAtDifferentLocations.isEmpty)
    }
}