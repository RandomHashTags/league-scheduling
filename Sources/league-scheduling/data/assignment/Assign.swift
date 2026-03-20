
// MARK: Assign
extension LeagueScheduleData {
    /// Assign a matchup pair to the given slot.
    /// 
    /// - Parameters:
    ///   - matchup: The associated matchup pair.
    ///   - slot: The slot to assign the `matchup`.
    /// - Returns: The final matchup data that was assigned.
    mutating func assign(
        matchup: MatchupPair,
        to slot: AvailableSlot,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup {
        return assignmentState.assign(
            matchup: matchup,
            to: slot,
            day: day,
            entriesCount: entriesCount,
            entryDivisions: entryDivisions,
            gameGap: gameGap,
            entryMatchupsPerGameDay: defaultMaxEntryMatchupsPerGameDay,
            divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval,
            canPlayAt: canPlayAt
        )
    }
}

extension AssignmentState {
    /// - Returns: The final matchup data that was assigned.
    /// - Warning: Assigns the literal pair. **DOES NOT** balance home/away.
    @discardableResult
    mutating func assign(
        matchup: MatchupPair,
        to slot: AvailableSlot,
        day: DayIndex,
        entriesCount: Int,
        entryDivisions: ContiguousArray<Division.IDValue>,
        gameGap: GameGap.TupleValue,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable
    ) -> Matchup {
        prioritizedEntries.removeMember(matchup.team1)
        prioritizedEntries.removeMember(matchup.team2)
        let home:Entry.IDValue = matchup.team1
        let away:Entry.IDValue = matchup.team2
        incrementRecurringDayLimits(home: home, away: away, entryDivisions: entryDivisions, divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval)

        incrementAssignData(home: home, away: away, slot: slot)
        insertPlaysAt(home: home, away: away, slot: slot)
        availableSlots.removeMember(slot)
        let leagueMatchup = Matchup(
            time: slot.time,
            location: slot.location,
            home: home,
            away: away
        )
        matchups.append(leagueMatchup)

        availableMatchups.removeMember(matchup)
        // TODO: fix (why is the following line necessary | it fixes an issue that allowed matchups to exceed the maximumSameOpponentsMatchupsCap, but availableMatchups still contains matchups that shouldn't be scheduled when scheduling b2b)
        availableMatchups.removeMember(.init(team1: matchup.team2, team2: matchup.team1))
        if playsAtTimes[unchecked: home].count == entryMatchupsPerGameDay {
            #if LOG
            remainingAllocations[unchecked: home].removeAll()
            #endif
            availableMatchups = availableMatchups.filter({ $0.team1 != home && $0.team2 != home })
        }
        if playsAtTimes[unchecked: away].count == entryMatchupsPerGameDay {
            #if LOG
            remainingAllocations[unchecked: away].removeAll()
            #endif
            availableMatchups = availableMatchups.filter({ $0.team1 != away && $0.team2 != away })
        }
        if numberOfAssignedMatchups[unchecked: home] == maximumPlayableMatchups[unchecked: home] {
            availableMatchups = availableMatchups.filter({ $0.team1 != home && $0.team2 != home })
        }
        if numberOfAssignedMatchups[unchecked: away] == maximumPlayableMatchups[unchecked: away] {
            availableMatchups = availableMatchups.filter({ $0.team1 != away && $0.team2 != away })
        }

        #if LOG
        availableMatchups.forEach { av in
            if assignedEntryHomeAways[unchecked: av.team1][unchecked: av.team2].sum == maxSameOpponentMatchups[unchecked: av.team1][unchecked: av.team2] {
                fatalError("assign;day=\(day);gameGap=\(gameGap);matchup=\(matchup);av=\(av);availableSlots.count=\(availableSlots.count);matchups.count=\(matchups.count)")
            } else if assignedEntryHomeAways[unchecked: av.team2][unchecked: av.team1].sum == maxSameOpponentMatchups[unchecked: av.team2][unchecked: av.team1] {
                fatalError("assign;day=\(day);gameGap=\(gameGap);matchup=\(matchup);av=\(av);availableSlots.count=\(availableSlots.count);matchups.count=\(matchups.count)")
            }
        }

        var string = "assign;day=\(day);matchup=\(matchup);slot=\(slot);availableMatchups.count=\(availableMatchups.count)"
        if availableMatchups.count <= 8 {
            string += ";availableMatchups=\(availableMatchups.map({ "\($0)" }))"
        }
        //string += ";recurringDayLimits=\(recurringDayLimits)"
        if availableSlots.first(where: { $0.time == slot.time }) == nil {
            string += ";filled slots for time"
        }
        print(string)
        #endif

        recalculateAllRemainingAllocations(
            day: day,
            entriesCount: entriesCount,
            gameGap: gameGap,
            canPlayAt: canPlayAt
        )
        return leagueMatchup
    }
}

// MARK: Increment assigned data
extension AssignmentState {
    mutating func incrementAssignData(
        home: Entry.IDValue,
        away: Entry.IDValue,
        slot: AvailableSlot
    ) {
        numberOfAssignedMatchups[unchecked: home] += 1
        numberOfAssignedMatchups[unchecked: away] += 1
        assignedTimes[unchecked: home][unchecked: slot.time] += 1
        assignedTimes[unchecked: away][unchecked: slot.time] += 1
        assignedLocations[unchecked: home][unchecked: slot.location] += 1
        assignedLocations[unchecked: away][unchecked: slot.location] += 1
        assignedEntryHomeAways[unchecked: home][unchecked: away].home += 1
        assignedEntryHomeAways[unchecked: away][unchecked: home].away += 1
        homeMatchups[unchecked: home] += 1
        awayMatchups[unchecked: away] += 1
    }
    mutating func insertPlaysAt(
        home: Entry.IDValue,
        away: Entry.IDValue,
        slot: AvailableSlot
    ) {
        playsAt[unchecked: home].insertMember(slot)
        playsAt[unchecked: away].insertMember(slot)
        playsAtTimes.insertMember(entryID: home, member: slot.time)
        playsAtTimes.insertMember(entryID: away, member: slot.time)
        playsAtLocations[unchecked: home].insert(slot.location)
        playsAtLocations[unchecked: away].insert(slot.location)
    }
}

// MARK: Increment RDL
extension AssignmentState {
    mutating func incrementRecurringDayLimits(
        home: Entry.IDValue,
        away: Entry.IDValue,
        entryDivisions: ContiguousArray<Division.IDValue>,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>
    ) {
        Self.incrementRecurringDayLimits(home: home, away: away, entryDivisions: entryDivisions, divisionRecurringDayLimitInterval: divisionRecurringDayLimitInterval, recurringDayLimits: &recurringDayLimits)
    }

    static func incrementRecurringDayLimits(
        home: Entry.IDValue,
        away: Entry.IDValue,
        entryDivisions: ContiguousArray<Division.IDValue>,
        divisionRecurringDayLimitInterval: ContiguousArray<RecurringDayLimitInterval>,
        recurringDayLimits: inout RecurringDayLimits
    ) {
        let recurringDayLimitInterval = divisionRecurringDayLimitInterval[unchecked: entryDivisions[unchecked: home]]
        recurringDayLimits[unchecked: home][unchecked: away] += recurringDayLimitInterval
        recurringDayLimits[unchecked: away][unchecked: home] += recurringDayLimitInterval
    }
}