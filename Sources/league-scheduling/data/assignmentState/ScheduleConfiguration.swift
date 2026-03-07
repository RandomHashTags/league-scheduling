
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype LocationSet:SetOfLocationIndexes

    typealias EntryRuntime = LeagueEntry.Runtime<TimeSet, LocationSet>
}

enum ScheduleConfig<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>: ScheduleConfiguration {
}