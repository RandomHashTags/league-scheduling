
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype RNG:RandomNumberGenerator & Sendable
    associatedtype DaySet:SetOfDayIndexes
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype LocationSet:SetOfLocationIndexes
    associatedtype EntryIDSet:SetOfEntryIDs
    associatedtype AvailableSlotSet:SetOfAvailableSlots
    associatedtype MatchupPairSet:AbstractSet where MatchupPairSet.Element == MatchupPair
    associatedtype MatchupSet:AbstractSet where MatchupSet.Element == Matchup
    associatedtype RedistributableMatchupSet:AbstractSet where RedistributableMatchupSet.Element == RedistributableMatchup
    associatedtype FlippableMatchupSet:AbstractSet where FlippableMatchupSet.Element == FlippableMatchup

    /// Current possible slot allocations for entries.
    /// 
    /// - Usage: [`Entry.IDValue`: `possible slot allocations`]
    typealias PossibleAllocations = ContiguousArray<AvailableSlotSet>
    typealias PlaysAt = ContiguousArray<AvailableSlotSet>
    typealias PlaysAtTimes = ContiguousArray<TimeSet>

    typealias DivisionRuntime = Division.Runtime<DaySet>
    typealias EntryRuntime = Entry.Runtime<DaySet, TimeSet, LocationSet>
}

enum ScheduleConfig<
        RNG: RandomNumberGenerator & Sendable,
        DaySet: SetOfDayIndexes,
        TimeSet: SetOfTimeIndexes,
        LocationSet: SetOfLocationIndexes,
        EntryIDSet: SetOfEntryIDs,
        AvailableSlotSet: SetOfAvailableSlots,
        MatchupPairSet: AbstractSet,
        MatchupSet: AbstractSet,
        RedistributableMatchupSet: AbstractSet,
        FlippableMatchupSet: AbstractSet
    >: ScheduleConfiguration where
        MatchupPairSet.Element == MatchupPair,
        MatchupSet.Element == Matchup,
        RedistributableMatchupSet.Element == RedistributableMatchup,
        FlippableMatchupSet.Element == FlippableMatchup
    {
}