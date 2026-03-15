
protocol SelectSlotProtocol: Sendable, ~Copyable {
    func select(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout Set<AvailableSlot>
    ) -> AvailableSlot?
}