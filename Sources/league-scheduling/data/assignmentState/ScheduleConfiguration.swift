
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype RNG:RandomNumberGenerator & Sendable
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype EntryIDSet:SetOfEntryIDs
    associatedtype AvailableSlotSet:SetOfAvailableSlots
    associatedtype MatchupPairSet:AbstractSet where MatchupPairSet.Element == MatchupPair
    associatedtype MatchupSet:AbstractSet where MatchupSet.Element == Matchup
    associatedtype FlippableMatchupSet:AbstractSet where FlippableMatchupSet.Element == FlippableMatchup

    typealias RemainingAllocations = ContiguousArray<AvailableSlotSet>
    typealias PlaysAt = ContiguousArray<AvailableSlotSet>
    typealias PlaysAtTimes = ContiguousArray<TimeSet>
}

enum ScheduleConfig<
        RNG: RandomNumberGenerator & Sendable,
        TimeSet: SetOfTimeIndexes,
        EntryIDSet: SetOfEntryIDs,
        AvailableSlotSet: SetOfAvailableSlots,
        MatchupPairSet: AbstractSet,
        MatchupSet: AbstractSet,
        FlippableMatchupSet: AbstractSet
    >: ScheduleConfiguration where
        MatchupPairSet.Element == MatchupPair,
        MatchupSet.Element == Matchup,
        FlippableMatchupSet.Element == FlippableMatchup
    {
}