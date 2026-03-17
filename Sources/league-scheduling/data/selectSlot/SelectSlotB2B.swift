
struct SelectSlotB2B: SelectSlotProtocol, ~Copyable {
    let entryMatchupsPerGameDay:EntryMatchupsPerGameDay

    func select<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playsAtTimes: ContiguousArray<TimeSet>,
        playsAtLocations: ContiguousArray<LocationSet>,
        playableSlots: inout Set<AvailableSlot>
    ) -> AvailableSlot? {
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
    private func filter<TimeSet: SetOfTimeIndexes>(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        playsAtTimes: ContiguousArray<TimeSet>,
        playableSlots: inout Set<AvailableSlot>
    ) {
        //print("filterSlotBack2Back;playsAtTimes[unchecked: team1].isEmpty=\(playsAtTimes[unchecked: team1].isEmpty);playsAtTimes[unchecked: team2].isEmpty=\(playsAtTimes[unchecked: team2].isEmpty)")
        if playsAtTimes[unchecked: team1].isEmpty && playsAtTimes[unchecked: team2].isEmpty {
            playableSlots = playableSlots.filter({ $0.time % entryMatchupsPerGameDay == 0 })
        }
    }
}