
@testable import LeagueScheduling
import Testing

struct DivisionEntryExpectations: ScheduleTestsProtocol {
    let cap:MaximumSameOpponentMatchupsCap
    let matchupsPlayedPerDay:ContiguousArray<ContiguousArray<Int>>
    let assignedEntryHomeAways:AssignedEntryHomeAways
    let entryMatchupsPerGameDay:EntryMatchupsPerGameDay
    let divisionEntries:[Entry.Runtime]

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