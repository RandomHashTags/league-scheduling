
struct SelectSlotB2B: SelectSlotProtocol, ~Copyable {
    let entryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay

    func select<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: ContiguousArray<TimeSet>,
        playsAtLocations: ContiguousArray<LocationSet>,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        filter(
            team1PlaysAtTimes: playsAtTimes[unchecked: team1],
            team2PlaysAtTimes: playsAtTimes[unchecked: team2],
            playableSlots: &playableSlots
        )
        return SelectSlotNormal.select(
            team1: team1,
            team2: team2,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: playableSlots
        )
    }
}

extension SelectSlotB2B {
    /// Mutates `playableSlots`, if `team1` AND `team2` haven't played already, so it only contains the first slots applicable for a matchup block.
    private func filter<TimeSet: SetOfTimeIndexes>(
        team1PlaysAtTimes: TimeSet,
        team2PlaysAtTimes: TimeSet,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) {
        //print("filterSlotBack2Back;playsAtTimes[unchecked: team1].isEmpty=\(playsAtTimes[unchecked: team1].isEmpty);playsAtTimes[unchecked: team2].isEmpty=\(playsAtTimes[unchecked: team2].isEmpty)")
        if team1PlaysAtTimes.isEmpty && team2PlaysAtTimes.isEmpty {
            playableSlots = playableSlots.filter({ $0.time % entryMatchupsPerGameDay == 0 })
        }
    }
}