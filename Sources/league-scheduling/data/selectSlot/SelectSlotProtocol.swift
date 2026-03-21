
protocol SelectSlotProtocol: Sendable, ~Copyable {
    func select<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playsAtTimes: borrowing PlaysAtTimesArray<TimeSet>,
        playsAtLocations: ContiguousArray<LocationSet>,
        playableSlots: inout some SetOfAvailableSlots & ~Copyable
    ) -> AvailableSlot?
}