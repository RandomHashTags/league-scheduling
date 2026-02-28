
import LeagueScheduling
import Testing

struct DayExpectations: ScheduleTestsProtocol {
    let settings:LeagueGeneralSettings.Runtime
    let b2bMatchupsAtDifferentLocations:Set<ValidLeagueMatchup>

    func expectations() {
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