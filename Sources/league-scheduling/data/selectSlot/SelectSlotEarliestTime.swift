
struct SelectSlotEarliestTime: SelectSlotProtocol, ~Copyable {
    func select<TimeSet: SetOfTimeIndexes>(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playsAtTimes: borrowing PlaysAtTimesArray<TimeSet>,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout some SetOfAvailableSlots
    ) -> AvailableSlot? {
        return Self.select(
            team1: team1,
            team2: team2,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: &playableSlots
        )
    }
}

extension SelectSlotEarliestTime {
    static func select(
        team1: Entry.IDValue,
        team2: Entry.IDValue,
        assignedTimes: AssignedTimes,
        assignedLocations: AssignedLocations,
        playableSlots: inout some SetOfAvailableSlots
    ) -> AvailableSlot? {
        filter(playableSlots: &playableSlots)
        return SelectSlotNormal.select(
            team1: team1,
            team2: team2,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: playableSlots
        )
    }

    /// Mutates `playableSlots` so it only contains the slots at the earliest available time.
    static func filter(playableSlots: inout some SetOfAvailableSlots) {
        var earliestTime = TimeIndex.max
        playableSlots.forEach { slot in
            if slot.time < earliestTime {
                earliestTime = slot.time
            }
        }
        playableSlots = playableSlots.filter({ earliestTime == $0.time })
    }
}