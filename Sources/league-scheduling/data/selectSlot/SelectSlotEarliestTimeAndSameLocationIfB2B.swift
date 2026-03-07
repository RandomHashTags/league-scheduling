
struct SelectSlotEarliestTimeAndSameLocationIfB2B: SelectSlotProtocol, ~Copyable {
    func select<TimeSet: SetOfTimeIndexes, LocationSet: SetOfLocationIndexes>(
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playsAtTimes: ContiguousArray<TimeSet>,
        playsAtLocations: ContiguousArray<LocationSet>,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        guard !playableSlots.isEmpty else { return nil }
        let homePlaysAtTimes = playsAtTimes[unchecked: team1]
        let awayPlaysAtTimes = playsAtTimes[unchecked: team1]
        guard !(homePlaysAtTimes.isEmpty || awayPlaysAtTimes.isEmpty) else {
            return SelectSlotEarliestTime.select(
                team1: team1,
                team2: team2,
                assignedTimes: assignedTimes,
                assignedLocations: assignedLocations,
                playableSlots: &playableSlots
            )
        }
        // at least one of the teams already plays
        let team1Times = assignedTimes[unchecked: team1]
        let team1Locations = assignedLocations[unchecked: team1]
        let team2Times = assignedTimes[unchecked: team2]
        let team2Locations = assignedLocations[unchecked: team2]

        let team1PlaysAtLocations = playsAtLocations[unchecked: team1]
        let team2PlaysAtLocations = playsAtLocations[unchecked: team2]

        var nonBackToBackSlots = [LeagueAvailableSlot]()
        nonBackToBackSlots.reserveCapacity(playableSlots.count)

        // TODO: fix | balancing of home/away can make the new home no longer play at home
        while !playableSlots.isEmpty, let targetSlot = SelectSlotNormal.select(
            team1Times: team1Times,
            team1Locations: team1Locations,
            team2Times: team2Times,
            team2Locations: team2Locations,
            playableSlots: playableSlots
        ) {
            if targetSlot.time > 0 && (homePlaysAtTimes.contains(targetSlot.time-1) || awayPlaysAtTimes.contains(targetSlot.time-1))
                    || homePlaysAtTimes.contains(targetSlot.time+1)
                    || awayPlaysAtTimes.contains(targetSlot.time+1) {
                // is back-to-back
                if team1PlaysAtLocations.contains(targetSlot.location) || team2PlaysAtLocations.contains(targetSlot.location) {
                    // make them play b2b on the same location
                    return targetSlot
                }
            } else {
                nonBackToBackSlots.append(targetSlot)
            }
            playableSlots.remove(targetSlot)
        }
        return nonBackToBackSlots.first
    }
}