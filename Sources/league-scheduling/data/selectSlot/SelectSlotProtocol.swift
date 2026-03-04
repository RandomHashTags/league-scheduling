
protocol SelectSlotProtocol: Sendable, ~Copyable {
    func select(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot?
}