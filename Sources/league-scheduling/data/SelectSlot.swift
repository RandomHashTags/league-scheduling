
// MARK: Select slot
extension LeagueScheduleData {
    typealias AvailableSlotClosure = @Sendable (
        _ entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        _ team1: LeagueEntry.IDValue,
        _ team2: LeagueEntry.IDValue,
        _ playsAtTimes: PlaysAtTimes,
        _ playsAtLocations: PlaysAtLocations,
        _ assignedTimes: LeagueAssignedTimes,
        _ assignedLocations: LeagueAssignedLocations,
        _ slots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot?
}

// MARK: Earliest time
extension LeagueScheduleData {
    static func getSlotEarliestTime(
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        filterSlotsEarliestTime(playableSlots: &playableSlots)
        return getSlot(
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            team1: team1,
            team2: team2,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: &playableSlots
        )
    }
    static func getSlotEarliestTimeAndSameLocationIfB2B(
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        guard !playableSlots.isEmpty else { return nil }
        let homePlaysAtTimes = playsAtTimes[unchecked: team1]
        let awayPlaysAtTimes = playsAtTimes[unchecked: team2]
        guard !(homePlaysAtTimes.isEmpty || awayPlaysAtTimes.isEmpty) else {
            return getSlotEarliestTime(
                entryMatchupsPerGameDay: entryMatchupsPerGameDay,
                team1: team1,
                team2: team2,
                playsAtTimes: playsAtTimes,
                playsAtLocations: playsAtLocations,
                assignedTimes: assignedTimes,
                assignedLocations: assignedLocations,
                playableSlots: &playableSlots
            )
        }
        // at least one of the teams already plays
        let team1Times = assignedTimes[unchecked: team1]
        let team1Locations = assignedLocations[unchecked: team1]
        let team1PlaysAtLocations = playsAtLocations[unchecked: team1]
        let team2Times = assignedTimes[unchecked: team2]
        let team2Locations = assignedLocations[unchecked: team2]
        let team2PlaysAtLocations = playsAtLocations[unchecked: team2]

        var nonBackToBackSlots = [LeagueAvailableSlot]()
        nonBackToBackSlots.reserveCapacity(playableSlots.count)

        // TODO: fix | balancing of home/away can make the new home no longer play at home
        while !playableSlots.isEmpty, let targetSlot = getSlot(
            team1Times: team1Times,
            team1Locations: team1Locations,
            team2Times: team2Times,
            team2Locations: team2Locations,
            playableSlots: &playableSlots
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

    /// Mutates `playableSlots` so it only contains the slots at the earliest available time.
    private static func filterSlotsEarliestTime(
        playableSlots: inout Set<LeagueAvailableSlot>
    ) {
        var earliestTime = LeagueTimeIndex.max
        for slot in playableSlots {
            if slot.time < earliestTime {
                earliestTime = slot.time
            }
        }
        playableSlots = playableSlots.filter({ earliestTime == $0.time })
    }
}

// MARK: Back-to-back
extension LeagueScheduleData {
    static func getSlotB2B(
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        filterSlotsBack2Back(
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            team1: team1,
            team2: team2,
            playsAtTimes: playsAtTimes,
            playableSlots: &playableSlots
        )
        return getSlot(
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            team1: team1,
            team2: team2,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            assignedTimes: assignedTimes,
            assignedLocations: assignedLocations,
            playableSlots: &playableSlots
        )
    }

    /// Mutates `playableSlots`, if `team1` AND `team2` haven't played already, so it only contains the first slots available applicable for a matchup block.
    private static func filterSlotsBack2Back(
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
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

// MARK: Same location
extension LeagueScheduleData {
    /// Mutates `playableSlots` so it only contains slots of `home`'s previously played locations.
    private static func filterSlotsHomeSameLocation(
        home: LeagueEntry.IDValue,
        playsAtLocations: PlaysAtLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) {
        let homePlaysAtLocations = playsAtLocations[unchecked: home]
        guard homePlaysAtLocations.count > 0 else { return }
        playableSlots = playableSlots.filter({ homePlaysAtLocations.contains($0.location) })
    }
}

// MARK: Default
extension LeagueScheduleData {
    /// Selects a slot from `playableSlots` based on the least number of matchups they've already played at the given times and locations.
    /// 
    /// - Note: Does **NOT** mutate `playableSlots`.
    static func getSlot(
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        team1: LeagueEntry.IDValue,
        team2: LeagueEntry.IDValue,
        playsAtTimes: PlaysAtTimes,
        playsAtLocations: PlaysAtLocations,
        assignedTimes: LeagueAssignedTimes,
        assignedLocations: LeagueAssignedLocations,
        playableSlots: inout Set<LeagueAvailableSlot>
    ) -> LeagueAvailableSlot? {
        guard !playableSlots.isEmpty else { return nil }
        let team1Times = assignedTimes[unchecked: team1]
        let team2Times = assignedTimes[unchecked: team2]
        let team1Locations = assignedLocations[unchecked: team1]
        let team2Locations = assignedLocations[unchecked: team2]
        return getSlot(
            team1Times: team1Times,
            team1Locations: team1Locations,
            team2Times: team2Times,
            team2Locations: team2Locations,
            playableSlots: &playableSlots
        )
    }

    /// Selects a slot from `playableSlots` based on the least number of matchups they've already played at the given times and locations.
    /// 
    /// - Note: **DOES NOT** mutate `playableSlots`.
    private static func getSlot(
        team1Times: ContiguousArray<UInt8>,
        team1Locations: ContiguousArray<UInt8>,
        team2Times: ContiguousArray<UInt8>,
        team2Locations: ContiguousArray<UInt8>,
        playableSlots: inout Set<LeagueAvailableSlot>
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