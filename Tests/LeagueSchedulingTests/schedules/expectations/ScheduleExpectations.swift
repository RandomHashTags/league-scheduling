
@testable import LeagueScheduling
import Testing

protocol ScheduleExpectations: Sendable {
}

// MARK: Expectations
extension ScheduleExpectations {
    func expectations<Config: ScheduleConfiguration>(
        settings: LeagueRequestPayload.Runtime<Config>,
        matchupsCount: Int,
        data: LeagueGenerationResult
    ) throws {
        guard !Task.isCancelled else { return }
        let regenerationAttempts:String = data.results.map {
            "assignLocationTimeRegenerationAttempts=\($0.assignLocationTimeRegenerationAttempts);negativeDayIndexRegenerationAttempts=\($0.negativeDayIndexRegenerationAttempts)"
        }.joined(separator: "\n")
        if false {
            for result in data.results {
                for (dayIndex, matchups) in result.schedule.enumerated() {
                    printMatchups(day: Int(dayIndex), matchups)
                }
            }
        }
        try #require(data.error == nil, Comment(stringLiteral: regenerationAttempts))
        try #require(data.results.count > 0)

        let gameDays = settings.gameDays
        let entryMatchupsPerGameDay = settings.general.defaultMaxEntryMatchupsPerGameDay
        let entriesPerLocation = settings.general.entriesPerLocation
        var maxStartingTimes:LeagueTimeIndex = 0
        var maxLocations:LeagueLocationIndex = 0
        for setting in settings.daySettings {
            if setting.startingTimes.count > maxStartingTimes {
                maxStartingTimes = LeagueTimeIndex(setting.startingTimes.count)
            }
            if setting.locations > maxLocations {
                maxLocations = setting.locations
            }
        }

        let entriesCount = settings.entries.count
        for result in data.results {
            let matchups = result.schedule
            var numberOfAssignedMatchups = [Int](repeating: 0, count: entriesCount)
            var assignedTimes = LeagueAssignedTimes(repeating: .init(repeating: UInt8(0), count: maxStartingTimes), count: entriesCount)
            var assignedLocations = LeagueAssignedLocations(repeating: .init(repeating: UInt8(0), count: maxLocations), count: entriesCount)
            var matchupsPerDay = ContiguousArray(repeating: UInt32(0), count: gameDays)
            var matchupsPlayedPerDay = ContiguousArray(repeating: ContiguousArray(repeating: 0, count: entriesCount), count: gameDays)
            var assignedEntryHomeAways = AssignedEntryHomeAways(repeating: .init(repeating: .init(home: 0, away: 0), count: entriesCount), count: entriesCount)
            let totalMatchupsPlayed = matchups.reduce(0, { $0 + $1.count })
            #expect(totalMatchupsPlayed == matchupsCount)
            for (dayIndex, matchups) in matchups.enumerated() {
                matchupsPerDay[unchecked: dayIndex] = UInt32(matchups.count)

                var b2bMatchupsAtDifferentLocations = Set<ValidLeagueMatchup>()
                var assignedSlots = [Set<LeagueAvailableSlot>](repeating: [], count: entriesCount)
                for matchup in matchups {
                    let home = matchup.home
                    let away = matchup.away
                    numberOfAssignedMatchups[unchecked: home] += 1
                    numberOfAssignedMatchups[unchecked: away] += 1
                    assignedTimes[unchecked: home][unchecked: matchup.time] += 1
                    assignedTimes[unchecked: away][unchecked: matchup.time] += 1
                    assignedLocations[unchecked: home][unchecked: matchup.location] += 1
                    assignedLocations[unchecked: away][unchecked: matchup.location] += 1
                    matchupsPlayedPerDay[unchecked: dayIndex][unchecked: home] += 1
                    matchupsPlayedPerDay[unchecked: dayIndex][unchecked: away] += 1
                    assignedEntryHomeAways[unchecked: home][unchecked: away].home += 1
                    assignedEntryHomeAways[unchecked: away][unchecked: home].away += 1

                    assignedSlots[unchecked: home].insert(matchup.slot)
                    assignedSlots[unchecked: away].insert(matchup.slot)
                    let homeSlots = assignedSlots[unchecked: home]
                    if homeSlots.count > 1 {
                        insertB2BSlotsAtDifferentLocations(
                            dayIndex: LeagueDayIndex(dayIndex),
                            matchup: matchup,
                            slots: homeSlots,
                            b2bMatchupsAtDifferentLocations: &b2bMatchupsAtDifferentLocations
                        )
                    }
                    let awaySlots = assignedSlots[unchecked: away]
                    if awaySlots.count > 1 {
                        insertB2BSlotsAtDifferentLocations(
                            dayIndex: LeagueDayIndex(dayIndex),
                            matchup: matchup,
                            slots: awaySlots,
                            b2bMatchupsAtDifferentLocations: &b2bMatchupsAtDifferentLocations
                        )
                    }
                }
                let settings = settings.daySettings[dayIndex]
                let dayExpectations = DayExpectations<Config>(
                    b2bMatchupsAtDifferentLocations: b2bMatchupsAtDifferentLocations
                )
                dayExpectations.expectations(settings)

                if true {
                    printMatchups(day: dayIndex, matchups)
                }
            }
            for (divisionIndex, division) in settings.divisions.enumerated() {
                let cap = division.maxSameOpponentMatchups
                let divisionEntries = settings.entries.filter { $0.division == divisionIndex }
                let divisionEntryExpectations = DivisionEntryExpectations<Config>(
                    cap: cap,
                    matchupsPlayedPerDay: matchupsPlayedPerDay,
                    assignedEntryHomeAways: assignedEntryHomeAways,
                    entryMatchupsPerGameDay: entryMatchupsPerGameDay
                )
                divisionEntryExpectations.expectations(
                    balanceHomeAway: settings.general.balanceHomeAway,
                    divisionEntries: divisionEntries
                )
            }

            #if UnitTesting
            #expect(assignedTimes == result.assignedTimes)
            #endif

            let balanceTimeNumber:LeagueTimeIndex
            if !settings.general.balancedTimes.isEmpty {
                balanceTimeNumber = LeagueSchedule.balanceNumber(
                    totalMatchupsPlayed: totalMatchupsPlayed,
                    value: settings.general.balancedTimes.count,
                    strictness: settings.general.balanceTimeStrictness
                )
            } else {
                balanceTimeNumber = .max
            }
            allocatedLessThanOrEqualToBalanceTimeNumber(
                assignedTimes: assignedTimes,
                balancedTimes: settings.general.balancedTimes,
                balanceTimeNumber: balanceTimeNumber
            )

            #if UnitTesting
            #expect(assignedLocations == result.assignedLocations)
            #endif

            let balanceLocationNumber:LeagueLocationIndex
            if !settings.general.balancedLocations.isEmpty {
                balanceLocationNumber = LeagueSchedule.balanceNumber(
                    totalMatchupsPlayed: totalMatchupsPlayed,
                    value: settings.general.balancedLocations.count,
                    strictness: settings.general.balanceLocationStrictness
                )
            } else {
                balanceLocationNumber = .max
            }
            allocatedLessThanOrEqualToBalanceLocationNumber(
                assignedLocations: assignedLocations,
                balancedLocations: settings.general.balancedLocations,
                balanceLocationNumber: balanceLocationNumber
            )

            let availableSlotsPerDay = maxLocations * maxStartingTimes
            let availableMatchupsPerDay = (entriesCount * entryMatchupsPerGameDay) / entriesPerLocation
            if let r = settings.general.redistributionSettings {
                let minMatchupsRequired = r.minMatchupsRequired
                for d in 0..<gameDays {
                    #expect(matchupsPerDay[unchecked: d] >= minMatchupsRequired)
                }
            } else {
                let expectedMatchupsPerDay = min(availableSlotsPerDay, UInt32(availableMatchupsPerDay))
                let expectedMatchupsPerDayArray = ContiguousArray<UInt32>(repeating: expectedMatchupsPerDay, count: gameDays)
                #expect(matchupsPerDay == expectedMatchupsPerDayArray)
            }

            if availableMatchupsPerDay == availableSlotsPerDay {
                // all available matchups per day can fit in the schedule perfectly
                let entriesPlayAllTheirMatchupsPerDay = entriesPerLocation * availableMatchupsPerDay == availableMatchupsPerDay
                if entriesPlayAllTheirMatchupsPerDay {
                    let expectedMatchupsPlayedPerDay = ContiguousArray(repeating: ContiguousArray(repeating: Int(entryMatchupsPerGameDay), count: entriesCount), count: gameDays)
                    #expect(matchupsPlayedPerDay == expectedMatchupsPlayedPerDay)
                }
            } else {
                // not all available matchups per day can be scheduled
            }

            for i in 0..<entriesCount {
                #expect(numberOfAssignedMatchups[unchecked: i] <= settings.general.maximumPlayableMatchups[i])
            }
        }
    }
}

// MARK: B2B slots at different locations
extension ScheduleExpectations {
    func insertB2BSlotsAtDifferentLocations(
        dayIndex: LeagueDayIndex,
        matchup: LeagueMatchup,
        slots: Set<LeagueAvailableSlot>,
        b2bMatchupsAtDifferentLocations: inout Set<ValidLeagueMatchup>
    ) {
        for slot in slots {
            var b2bTimes = Set<LeagueTimeIndex>()
            if slot.time > 0 {
                b2bTimes.insert(slot.time-1)
            }
            b2bTimes.insert(slot.time+1)
            let b2bSlotsAtDifferentLocation = slots.filter({ b2bTimes.contains($0.time) && $0.location != slot.location })
            if !b2bSlotsAtDifferentLocation.isEmpty {
                b2bMatchupsAtDifferentLocations.insert(.init(day: LeagueDayIndex(dayIndex), matchup: matchup))
            }
        }
    }
}

// MARK: Assigned times
extension ScheduleExpectations {
    private func allocatedLessThanOrEqualToBalanceTimeNumber(
        assignedTimes: LeagueAssignedTimes,
        balancedTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        balanceTimeNumber: LeagueTimeIndex
    ) {
        for (entryID, assignedTimes) in assignedTimes.enumerated() {
            for (timeIndex, assignedTime) in assignedTimes.enumerated() {
                guard balancedTimes.contains(LeagueTimeIndex(timeIndex)) else { continue }
                #expect(assignedTime <= balanceTimeNumber, Comment("entryID=\(entryID);timeIndex=\(timeIndex);assignedTime=\(assignedTime);balanceTimeNumber=\(balanceTimeNumber)"))
            }
        }
    }
}

// MARK: Assigned locations
extension ScheduleExpectations {
    private func allocatedLessThanOrEqualToBalanceLocationNumber(
        assignedLocations: LeagueAssignedLocations,
        balancedLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        balanceLocationNumber: LeagueLocationIndex
    ) {
        for (entryID, assignedLocations) in assignedLocations.enumerated() {
            for (locationIndex, assignedLocation) in assignedLocations.enumerated() {
                guard balancedLocations.contains(LeagueLocationIndex(locationIndex)) else { continue }
                #expect(assignedLocation <= balanceLocationNumber, Comment("entryID=\(entryID);locationIndex=\(locationIndex);assignedLocation=\(assignedLocation);balanceLocationNumber=\(balanceLocationNumber)"))
            }
        }
    }
}

// MARK: Print matchups
extension ScheduleExpectations {
    func printMatchups(
        day: Int,
        _ matchups: Set<LeagueMatchup>
    ) {
        return
        let results:String = matchups.sorted(by: {
            guard $0.time == $1.time else { return $0.time < $1.time }
            return $0.location < $1.location
        }).map({ "day \(day) | time \($0.time) | location \($0.location) | \($0.away) @ \($0.home)" }).joined(separator: "\n")
        print(results)
    }
}