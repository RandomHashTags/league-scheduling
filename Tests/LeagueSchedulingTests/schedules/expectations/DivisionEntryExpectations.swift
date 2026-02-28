
@testable import LeagueScheduling
import Testing

struct DivisionEntryExpectations: ScheduleTestsProtocol {
    let cap:LeagueMaximumSameOpponentMatchupsCap
    let matchupsPlayedPerDay:ContiguousArray<ContiguousArray<Int>>
    let assignedEntryHomeAways:AssignedEntryHomeAways
    let entryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay
    let divisionEntries:[LeagueEntry.Runtime]

    func expectations(
        balanceHomeAway: Bool
    ) {
        if balanceHomeAway {
            BalanceHomeAwayExpectations().expectations(
                cap: cap,
                matchupsPlayedPerDay: matchupsPlayedPerDay,
                assignedEntryHomeAways: assignedEntryHomeAways,
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                divisionEntries: divisionEntries
            )
        }
    }
}