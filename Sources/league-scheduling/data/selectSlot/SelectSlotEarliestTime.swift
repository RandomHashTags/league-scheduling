
struct SelectSlotEarliestTime: SelectSlotProtocol, ~Copyable {
    func select<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: ContiguousArray<TimeSet>,
        playsAtLocations: ContiguousArray<LocationSet>,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
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
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
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
    static func filter(playableSlots: inout Set<LeagueAvailableSlot>) {
        var earliestTime = LeagueTimeIndex.max
        for slot in playableSlots {
            if slot.time < earliestTime {
                earliestTime = slot.time
            }
        }
        playableSlots = playableSlots.filter({ earliestTime == $0.time })
    }
}