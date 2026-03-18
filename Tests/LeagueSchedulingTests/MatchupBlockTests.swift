
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct MatchupBlockTests: ScheduleExpectations {
}

// MARK: Adjacent times
extension MatchupBlockTests {
    @Test(.timeLimit(.minutes(1)))
    func adjacentTimes() {
        var adjacent = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 2)
        #expect(adjacent == [1])

        adjacent = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 3)
        #expect(adjacent == [1, 2])

        adjacent = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 4)
        #expect(adjacent == [1, 2, 3])


        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 2)
        #expect(adjacent == [0])

        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 3)
        #expect(adjacent == [0, 2])

        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 4)
        #expect(adjacent == [0, 2, 3])


        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 2)
        #expect(adjacent == [3])

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 3)
        #expect(adjacent == [0, 1])

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 4)
        #expect(adjacent == [0, 1, 3])

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 5)
        #expect(adjacent == [0, 1, 3, 4])
    }
}