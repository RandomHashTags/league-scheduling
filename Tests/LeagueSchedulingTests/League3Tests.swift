
@testable import LeagueScheduling
import Testing

struct League3Tests: ScheduleExpectations {
    private static func throughput() async throws -> (success: UInt64, fail: UInt64) {
        var throughput:UInt64 = 0
        var failed = [String:Int]()
        let schedule = try ScheduleBeanBagToss.schedule8GameDays3Times3Locations1Division9Teams()
        //let schedule = try ScheduleMisc.schedule10GameDays4Times5Locations2Divisions20Teams2Matchups()
        while !Task.isCancelled {
            let result = await LeagueSchedule.generate(schedule)
            throughput += 1
            if let e = result.error, !e.contains("(timed out;") {
                failed[e, default: 0] += 1
            }
        }
        if !failed.isEmpty, failed.count < 10 {
            print("failed=\(failed)")
        }
        return (throughput, UInt64(failed.reduce(0) { $0 + $1.value }))
    }

    @Test(.timeLimit(.minutes(1)))
    func testthroughput() async throws {
        try await withThrowingTaskGroup(of: (success: UInt64, fail: UInt64).self) { group in
            for _ in 0..<5 {
                group.addTask {
                    return try await Self.throughput()
                }
            }
            var throughput:UInt64 = 0
            var failed:UInt64 = 0
            for try await test in group {
                throughput += test.success
                failed += test.fail
            }
            print("testthroughput;throughput=\(throughput);failed=\(failed) (\((Double(failed) / Double(throughput) * 100))%)")
        }
    }
}