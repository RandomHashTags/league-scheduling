
@testable import LeagueScheduling
import StaticDateTimes
import Testing

// MARK: All
@Suite
struct DivisionMatchupCombinationTests {
    @Test(.timeLimit(.minutes(1)))
    func allDivisionMatchupCombinations() {
        var expected:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = [
            [
                [0, 6], [2, 4], [3, 3], [4, 2], [6, 0]
            ]
        ]
        expected += expected
        var combos = calculateAllDivisionMatchupCombinations(
            entriesPerMatchup: 2,
            locations: 6,
            entryCountsForDivision: [12, 12]
        )
        #expect(combos == expected)

        expected = [
            [
                [2, 5], [3, 4], [4, 3], [5, 2]
            ],
            [
                [0, 5], [2, 3], [3, 2], [5, 0]
            ]
        ]
        combos = calculateAllDivisionMatchupCombinations(
            entriesPerMatchup: 2,
            locations: 6,
            entryCountsForDivision: [14, 10]
        )
        #expect(combos == expected)

        expected = [
            [
                [2, 5], [3, 4], [4, 3], [5, 2]
            ],
            [],
            [
                [0, 5], [2, 3], [3, 2], [5, 0]
            ]
        ]
        combos = calculateAllDivisionMatchupCombinations(
            entriesPerMatchup: 2,
            locations: 6,
            entryCountsForDivision: [14, 0, 10]
        )
        #expect(combos == expected)
    }
}

// MARK: Allowed
extension DivisionMatchupCombinationTests {
    @Test(.timeLimit(.minutes(1)))
    func allowedDivisionMatchupCombinations() {
        var expected:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = [
            [
                [0, 6], [6, 0]
            ],
            [
                [2, 4], [4, 2]
            ],
            [
                [3, 3], [3, 3]
            ],
            [
                [4, 2], [2, 4]
            ],
            [
                [6, 0], [0, 6]
            ]
        ]
        var combos = calculateAllowedDivisionMatchupCombinations(
            entriesPerMatchup: 2,
            locations: 6,
            entryCountsForDivision: [12, 12]
        )
        #expect(combos == expected)

        expected = [
            [
                [3, 4], [3, 2]
            ],
            [
                [4, 3], [2, 3]
            ]
        ]
        combos = calculateAllowedDivisionMatchupCombinations(
            entriesPerMatchup: 2,
            locations: 6,
            entryCountsForDivision: [14, 10]
        )
        #expect(combos == expected)
    }
}