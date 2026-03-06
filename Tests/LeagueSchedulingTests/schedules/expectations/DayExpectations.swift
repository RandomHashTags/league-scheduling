
@testable import LeagueScheduling
import Testing

struct DayExpectations: ScheduleTestsProtocol {
    let b2bMatchupsAtDifferentLocations:Set<ValidLeagueMatchup>

    func expectations(_ settings: some LeagueGeneralSettings.RuntimeProtocol) {
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