
import OrderedCollections

protocol ScheduleConfiguration: Sendable, ~Copyable {
    associatedtype RNG:RandomNumberGenerator & Sendable
    associatedtype TimeSet:SetOfTimeIndexes

    associatedtype DeterministicEntryIDSet:SetOfEntryIDs
    associatedtype DeterministicAvailableSlotSet:SetOfAvailableSlots
    associatedtype DeterministicMatchupPairSet:SetOfMatchupPair

    typealias RemainingAllocations = ContiguousArray<DeterministicAvailableSlotSet>
    typealias PlaysAt = ContiguousArray<DeterministicAvailableSlotSet>
    typealias PlaysAtTimes = ContiguousArray<TimeSet>
}

enum ScheduleConfig<
        RNG: RandomNumberGenerator & Sendable,
        TimeSet: SetOfTimeIndexes,
        DeterministicEntryIDSet: SetOfEntryIDs,
        DeterministicAvailableSlotSet: SetOfAvailableSlots,
        DeterministicMatchupPairSet: SetOfMatchupPair
    >: ScheduleConfiguration {
}