
struct SelectSlotB2B: SelectSlotProtocol, ~Copyable {
    let entryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay

    func select(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        filter(
            team1: team1,
            team2: team2,
            playsAtTimes: playsAtTimes,
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
    private func filter(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        playsAtTimes: PlaysAtTimes,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) {
        //print("filterSlotBack2Back;playsAtTimes[unchecked: team1].isEmpty=\(playsAtTimes[unchecked: team1].isEmpty);playsAtTimes[unchecked: team2].isEmpty=\(playsAtTimes[unchecked: team2].isEmpty)")
        if playsAtTimes[unchecked: team1].isEmpty && playsAtTimes[unchecked: team2].isEmpty {
            playableSlots = playableSlots.filter({ $0.time % entryMatchupsPerGameDay == 0 })
        }
    }
}