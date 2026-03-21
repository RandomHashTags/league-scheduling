
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype RNG:RandomNumberGenerator & Sendable
    associatedtype TimeSet:SetOfTimeIndexes
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
}

enum ScheduleConfig<
        RNG: RandomNumberGenerator & Sendable,
        TimeSet: SetOfTimeIndexes,
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