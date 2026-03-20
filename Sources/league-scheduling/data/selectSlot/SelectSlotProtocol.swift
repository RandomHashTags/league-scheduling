
protocol SelectSlotProtocol: Sendable, ~Copyable {
    func select<TimeSet: SetOfTimeIndexes>(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playsAtTimes: borrowing PlaysAtTimesArray<TimeSet>,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout some SetOfAvailableSlots
    ) -> AvailableSlot?
}