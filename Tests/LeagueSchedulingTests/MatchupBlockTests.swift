
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
        var adjacent:BitSet64<TimeIndex> = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 2)
        #expect(adjacent == .init([1]))

        adjacent = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 3)
        #expect(adjacent == .init([1, 2]))

        adjacent = calculateAdjacentTimes(for: 0, entryMatchupsPerGameDay: 4)
        #expect(adjacent == .init([1, 2, 3]))


        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 2)
        #expect(adjacent == .init([0]))

        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 3)
        #expect(adjacent == .init([0, 2]))

        adjacent = calculateAdjacentTimes(for: 1, entryMatchupsPerGameDay: 4)
        #expect(adjacent == .init([0, 2, 3]))


        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 2)
        #expect(adjacent == .init([3]))

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 3)
        #expect(adjacent == .init([0, 1]))

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 4)
        #expect(adjacent == .init([0, 1, 3]))

        adjacent = calculateAdjacentTimes(for: 2, entryMatchupsPerGameDay: 5)
        #expect(adjacent == .init([0, 1, 3, 4]))
    }
}

extension BitSet64: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}
extension BitSet128: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}