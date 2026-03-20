
protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype RNG:RandomNumberGenerator & Sendable
    associatedtype TimeSet:SetOfTimeIndexes
    associatedtype EntryIDSet:SetOfEntryIDs
    associatedtype AvailableSlotSet:SetOfAvailableSlots
    associatedtype MatchupPairSet:SetOfMatchupPair
    associatedtype MatchupSet:SetOfMatchup

    typealias RemainingAllocations = ContiguousArray<AvailableSlotSet>
    typealias PlaysAt = ContiguousArray<AvailableSlotSet>
    typealias PlaysAtTimes = ContiguousArray<TimeSet>
}

enum ScheduleConfig<
        RNG: RandomNumberGenerator & Sendable,
        TimeSet: SetOfTimeIndexes,
        EntryIDSet: SetOfEntryIDs,
        AvailableSlotSet: SetOfAvailableSlots,
        MatchupPairSet: SetOfMatchupPair,
        MatchupSet: SetOfMatchup
    >: ScheduleConfiguration {
}