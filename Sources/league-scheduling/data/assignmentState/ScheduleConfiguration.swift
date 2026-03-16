
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype DaySet:SetOfDayIndexes
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype LocationSet:SetOfLocationIndexes
    associatedtype EntryIDSet:SetOfEntryIDs

    typealias DivisionRuntime = Division.Runtime<DaySet>
    typealias EntryRuntime = Entry.Runtime<DaySet, TimeSet, LocationSet>
}

enum ScheduleConfig<
        DaySet: SetOfDayIndexes,
        TimeSet: SetOfTimeIndexes,
        LocationSet: SetOfLocationIndexes,
        EntryIDSet: SetOfEntryIDs
    >: ScheduleConfiguration {
}