
@testable import LeagueScheduling
import Testing

struct BalancedHomeAwayThroughput: ScheduleTestsProtocol {
    //@Test(.timeLimit(.minutes(1)))
    func balancedHomeAway() async throws {
        try await withThrowingTaskGroup(of: Output.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    return try await balanceHomeAway()
                }
            }
            var output = Output()
            for try await test in group {
                output.append(test)
            }
            let successfulGenerations = output.throughput - output.failedGenerations
            let generationSuccessRate = (Double(successfulGenerations) / Double(output.throughput)) * 100
            let balanceHomeAwaySuccessRate = (Double(output.properlyBalancedHomeAway) / Double(successfulGenerations)) * 100
            print("balancedHomeAway;generationSuccessRate=\(generationSuccessRate)%;balanceHomeAwaySuccessRate=\(balanceHomeAwaySuccessRate)%;output=\(output)")
        }
    }
    private func balanceHomeAway() async throws -> Output {
        var output = Output()
        let schedule = try ScheduleBack2Back.scheduleB2B_11GameDays4Times6Locations2Divisions24Teams14_10()
        let entries = schedule.entries
        let entriesCount = entries.count
        let expectation = BalanceHomeAwayExpectations<UnitTestScheduleConfig>()
        while !Task.isCancelled {
            let result = await schedule.generate()
            output.throughput += 1
            if result.error == nil {
                guard let resultData = result.results.first else { continue }
                var assignedEntryHomeAways = AssignedEntryHomeAways(repeating: .init(repeating: .init(home: 0, away: 0), count: entriesCount), count: entriesCount)
                for matchups in resultData.schedule {
                    for matchup in matchups {
                        let home = matchup.home
                        let away = matchup.away
                        assignedEntryHomeAways[unchecked: home][unchecked: away].home += 1
                        assignedEntryHomeAways[unchecked: away][unchecked: home].away += 1
                    }
                }
                let matchupsPerGameDay = MatchupsPlayedPerGameDay.get(
                    gameDays: schedule.gameDays,
                    entriesCount: entries.count,
                    schedule: resultData.schedule
                )
                var isBalanced = true
                for entry in entries {
                    if !expectation.isBalanced(
                        entry: entry,
                        matchupsPlayedPerDay: matchupsPerGameDay,
                        assignedEntryHomeAways: assignedEntryHomeAways,
                        entryMatchupsPerGameDay: schedule.general.defaultMaxEntryMatchupsPerGameDay
                    ) {
                        isBalanced = false
                        break
                    }
                }
                if isBalanced {
                    output.properlyBalancedHomeAway += 1
                }
            } else {
                output.failedGenerations += 1
            }
        }
        return output
    }

    struct Output: Sendable {
        var throughput:UInt64 = 0
        var failedGenerations:UInt64 = 0
        var properlyBalancedHomeAway:UInt64 = 0

        mutating func append(_ output: Self) {
            throughput += output.throughput
            failedGenerations += output.failedGenerations
            properlyBalancedHomeAway += output.properlyBalancedHomeAway
        }
    }
}