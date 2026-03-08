
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype DaySet:SetOfDayIndexes
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype LocationSet:SetOfLocationIndexes
    associatedtype EntryIDSet:SetOfEntryIDs

    typealias DivisionRuntime = LeagueDivision.Runtime<DaySet>
    typealias EntryRuntime = LeagueEntry.Runtime<DaySet, TimeSet, LocationSet>
}

enum ScheduleConfig<
        DaySet: SetOfDayIndexes,
        TimeSet: SetOfTimeIndexes,
        LocationSet: SetOfLocationIndexes,
        EntryIDSet: SetOfEntryIDs
    >: ScheduleConfiguration {
}