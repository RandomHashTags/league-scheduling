
struct SelectSlotNormal: SelectSlotProtocol, ~Copyable {
    func select(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        return Self.select(
            team1: team1,
            team2: team2,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: playableSlots
        )
    }
}

extension SelectSlotNormal {
    /// Selects a slot from `playableSlots` based on the least number of matchups they've already played at the given times and locations.
    static func select(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        guard !playableSlots.isEmpty else { return nil }
        let team1Times = assignedTimes[unchecked: team1]
        let team2Times = assignedTimes[unchecked: team2]
        let team1Locations = assignedLocations[unchecked: team1]
        let team2Locations = assignedLocations[unchecked: team2]
        return select(
            team1Times: team1Times,
            team1Locations: team1Locations,
            team2Times: team2Times,
            team2Locations: team2Locations,
            playableSlots: playableSlots
        )
    }

    /// Selects a slot from `playableSlots` based on the least number of matchups they've already played at the given times and locations.
    static func select(
        team1Times: LeagueAssignedTimes.Element,
        team1Locations: LeagueAssignedLocations.Element,
        team2Times: LeagueAssignedTimes.Element,
        team2Locations: LeagueAssignedLocations.Element,
        playableSlots: Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        var selected = getSelectedSlot(playableSlots[playableSlots.startIndex], team1Times, team1Locations, team2Times, team2Locations)
        for slot in playableSlots[playableSlots.index(after: playableSlots.startIndex)...] {
            let minimum = getMinimumAssigned(slot, team1Times, team1Locations, team2Times, team2Locations)
            if minimum <= selected.minimumAssigned {
                selected.slot = slot
                selected.minimumAssigned = minimum
            }
        }
        return selected.slot
    }

    private static func getSelectedSlot(
        _ slot: LeagueAvailableSlot,
        _ team1Times: LeagueAssignedTimes.Element,
        _ team1Locations: LeagueAssignedLocations.Element,
        _ team2Times: LeagueAssignedTimes.Element,
        _ team2Locations: LeagueAssignedLocations.Element
    ) -> SelectedSlot {
        return SelectedSlot(slot: slot, minimumAssigned: getMinimumAssigned(slot, team1Times, team1Locations, team2Times, team2Locations))
    }
    private static func getMinimumAssigned(
        _ slot: LeagueAvailableSlot,
        _ team1Times: LeagueAssignedTimes.Element,
        _ team1Locations: LeagueAssignedLocations.Element,
        _ team2Times: LeagueAssignedTimes.Element,
        _ team2Locations: LeagueAssignedLocations.Element
    ) -> UInt8 {
        return min(
            min(team1Times[unchecked: slot.time], team1Locations[unchecked: slot.location]),
            min(team2Times[unchecked: slot.time], team2Locations[unchecked: slot.location])
        )
    }

    struct SelectedSlot: Sendable, ~Copyable {
        var slot:LeagueAvailableSlot
        var minimumAssigned:UInt8
    }
}