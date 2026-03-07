
@testable import LeagueScheduling
import Testing

struct DivisionEntryExpectations<Config: ScheduleConfiguration>: ScheduleTestsProtocol {
    let cap:LeagueMaximumSameOpponentMatchupsCap
    let matchupsPlayedPerDay:ContiguousArray<ContiguousArray<Int>>
    let assignedEntryHomeAways:AssignedEntryHomeAways
    let entryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay

    func expectations(
        balanceHomeAway: Bool,
        divisionEntries: [Config.EntryRuntime]
    ) {
        if balanceHomeAway {
            BalanceHomeAwayExpectations<Config>().expectations(
                cap: cap,
                matchupsPlayedPerDay: matchupsPlayedPerDay,
                assignedEntryHomeAways: assignedEntryHomeAways,
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                divisionEntries: divisionEntries
            )
        }
    }
}