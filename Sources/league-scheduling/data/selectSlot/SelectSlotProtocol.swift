
protocol SelectSlotProtocol: Sendable, ~Copyable {
    func select(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        team1PlaysAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        team1PlaysAtLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        team2PlaysAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        team2PlaysAtLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot?
}