
@testable import LeagueScheduling
import Testing

struct BalanceNumberCalculation {
    @Test(arguments: [BalanceStrictness.lenient, .relaxed, .normal, .very])
    func balanceNumberCalculation(strictness: BalanceStrictness) {
        // `totalMatchupsPlayed` = total number of matchups played by a single entry/team in a schedule
        // `value` = number of available times/locations
        let mutateMinimum:(_ value: inout Int) -> Void
        switch strictness {
        case .lenient: mutateMinimum = { $0 = .max }
        case .relaxed: mutateMinimum = { $0 += 2 }
        case .normal:  mutateMinimum = { $0 += 1 }
        case .very:    mutateMinimum = { _ in }
        case .UNRECOGNIZED: fatalError()
        }
        var minimumRequired = 4
        mutateMinimum(&minimumRequired)
        var balanceNumber:Int = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 16,
            value: 4,
            strictness: strictness
        )
        #expect(balanceNumber == minimumRequired)

        minimumRequired = 6
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 16,
            value: 3,
            strictness: strictness
        )
        #expect(balanceNumber == minimumRequired)

        minimumRequired = 8
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 16,
            value: 2,
            strictness: strictness
        )
        #expect(balanceNumber == minimumRequired)

        minimumRequired = 3
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 5,
            value: 2,
            strictness: strictness
        )
        #expect(balanceNumber == minimumRequired)

        minimumRequired = 5
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 5,
            value: 1,
            strictness: strictness
        )
        #expect(balanceNumber == minimumRequired)

        minimumRequired = 3
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 9,
            value: 3,
            strictness: strictness
        )

        minimumRequired = 2
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 7,
            value: 4,
            strictness: strictness
        )

        minimumRequired = 3
        mutateMinimum(&minimumRequired)
        balanceNumber = LeagueSchedule.balanceNumber(
            totalMatchupsPlayed: 7,
            value: 3,
            strictness: strictness
        )
    }
}