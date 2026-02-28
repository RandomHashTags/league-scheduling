
import StaticDateTimes

// MARK: typealiases
extension LeagueScheduleData {
    typealias CanPlayAtClosure = @Sendable (
        _ startingTimes: [StaticTime],
        _ matchupDuration: LeagueMatchupDuration,
        _ travelDurations: [[LeagueMatchupDuration]],
        _ time: LeagueTimeIndex,
        _ location: LeagueLocationIndex,
        _ allowedTimes: Set<LeagueTimeIndex>,
        _ allowedLocations: Set<LeagueLocationIndex>,
        _ playsAt: PlaysAt.Element,
        _ playsAtTimes: PlaysAtTimes.Element,
        _ playsAtLocations: PlaysAtLocations.Element,
        _ timeNumber: UInt8,
        _ locationNumber: UInt8,
        _ maxTimeNumber: LeagueTimeIndex,
        _ maxLocationNumber: LeagueLocationIndex,
        _ gameGap: GameGap.TupleValue
    ) -> Bool
    typealias OptimizedTeamCanPlayAtClosure = @Sendable (
        _ startingTimes: [StaticTime],
        _ matchupDuration: LeagueMatchupDuration,
        _ travelDurations: [[LeagueMatchupDuration]],
        _ time: LeagueTimeIndex,
        _ location: LeagueLocationIndex,
        _ gameGap: GameGap.TupleValue,
        _ team1AllowedTimes: Set<LeagueTimeIndex>,
        _ team1AllowedLocations: Set<LeagueLocationIndex>,
        _ team1PlaysAt: PlaysAt.Element,
        _ team1PlaysAtTimes: PlaysAtTimes.Element,
        _ team1PlaysAtLocations: PlaysAtLocations.Element,
        _ team1TimeNumbers: LeagueAssignedTimes.Element,
        _ team1LocationNumbers: LeagueAssignedLocations.Element,
        _ maxTeam1TimeNumbers: MaximumTimeAllocations.Element,
        _ maxTeam1LocationNumbers: MaximumLocationAllocations.Element,
        _ team2AllowedTimes: Set<LeagueTimeIndex>,
        _ team2AllowedLocations: Set<LeagueLocationIndex>,
        _ team2PlaysAt: PlaysAt.Element,
        _ team2PlaysAtTimes: PlaysAtTimes.Element,
        _ team2PlaysAtLocations: PlaysAtLocations.Element,
        _ team2TimeNumbers: LeagueAssignedTimes.Element,
        _ team2LocationNumbers: LeagueAssignedLocations.Element,
        _ maxTeam2TimeNumbers: MaximumTimeAllocations.Element,
        _ maxTeam2LocationNumbers: MaximumLocationAllocations.Element
    ) -> Bool
}

// MARK: LeagueMatchupPair
extension LeagueScheduleData {
    /// - Returns: Whether or not a matchup pair can play at the given time and location, taking into account their matchup history.
    /// - Warning: Doesn't check whether the pair has already played the maximum allowed for day (`entryMatchupsPerGameDay`)!
    static func canPlayAt(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        gameGap: GameGap.TupleValue,
        team1AllowedTimes: Set<LeagueTimeIndex>,
        team1AllowedLocations: Set<LeagueLocationIndex>,
        team1PlaysAt: PlaysAt.Element,
        team1PlaysAtTimes: PlaysAtTimes.Element,
        team1PlaysAtLocations: PlaysAtLocations.Element,
        team1TimeNumbers: LeagueAssignedTimes.Element,
        team1LocationNumbers: LeagueAssignedLocations.Element,
        maxTeam1TimeNumbers: MaximumTimeAllocations.Element,
        maxTeam1LocationNumbers: MaximumLocationAllocations.Element,
        team2AllowedTimes: Set<LeagueTimeIndex>,
        team2AllowedLocations: Set<LeagueLocationIndex>,
        team2PlaysAt: PlaysAt.Element,
        team2PlaysAtTimes: PlaysAtTimes.Element,
        team2PlaysAtLocations: PlaysAtLocations.Element,
        team2TimeNumbers: LeagueAssignedTimes.Element,
        team2LocationNumbers: LeagueAssignedLocations.Element,
        maxTeam2TimeNumbers: MaximumTimeAllocations.Element,
        maxTeam2LocationNumbers: MaximumLocationAllocations.Element
    ) -> Bool {
        return canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            gameGap: gameGap,
            allowedTimes: team1AllowedTimes,
            allowedLocations: team1AllowedLocations,
            playsAt: team1PlaysAt,
            playsAtTimes: team1PlaysAtTimes,
            playsAtLocations: team1PlaysAtLocations,
            timeNumbers: team1TimeNumbers,
            locationNumbers: team1LocationNumbers,
            maxTimeNumbers: maxTeam1TimeNumbers,
            maxLocationNumbers: maxTeam1LocationNumbers
        )
        && canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            gameGap: gameGap,
            allowedTimes: team2AllowedTimes,
            allowedLocations: team2AllowedLocations,
            playsAt: team2PlaysAt,
            playsAtTimes: team2PlaysAtTimes,
            playsAtLocations: team2PlaysAtLocations,
            timeNumbers: team2TimeNumbers,
            locationNumbers: team2LocationNumbers,
            maxTimeNumbers: maxTeam2TimeNumbers,
            maxLocationNumbers: maxTeam2LocationNumbers
        )
    }

    static func canPlayAtSameLocationIfB2B(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        gameGap: GameGap.TupleValue,
        team1AllowedTimes: Set<LeagueTimeIndex>,
        team1AllowedLocations: Set<LeagueLocationIndex>,
        team1PlaysAt: PlaysAt.Element,
        team1PlaysAtTimes: PlaysAtTimes.Element,
        team1PlaysAtLocations: PlaysAtLocations.Element,
        team1TimeNumbers: LeagueAssignedTimes.Element,
        team1LocationNumbers: LeagueAssignedLocations.Element,
        maxTeam1TimeNumbers: MaximumTimeAllocations.Element,
        maxTeam1LocationNumbers: MaximumLocationAllocations.Element,
        team2AllowedTimes: Set<LeagueTimeIndex>,
        team2AllowedLocations: Set<LeagueLocationIndex>,
        team2PlaysAt: PlaysAt.Element,
        team2PlaysAtTimes: PlaysAtTimes.Element,
        team2PlaysAtLocations: PlaysAtLocations.Element,
        team2TimeNumbers: LeagueAssignedTimes.Element,
        team2LocationNumbers: LeagueAssignedLocations.Element,
        maxTeam2TimeNumbers: MaximumTimeAllocations.Element,
        maxTeam2LocationNumbers: MaximumLocationAllocations.Element
    ) -> Bool {
        return canPlayAtSameLocationIfB2B(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            allowedTimes: team1AllowedTimes,
            allowedLocations: team1AllowedLocations,
            playsAt: team1PlaysAt,
            playsAtTimes: team1PlaysAtTimes,
            playsAtLocations: team1PlaysAtLocations,
            timeNumber: team1TimeNumbers[unchecked: time],
            locationNumber: team1LocationNumbers[unchecked: location],
            maxTimeNumber: maxTeam1TimeNumbers[unchecked: time],
            maxLocationNumber: maxTeam1LocationNumbers[unchecked: location],
            gameGap: gameGap
        )
        && canPlayAtSameLocationIfB2B(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            allowedTimes: team2AllowedTimes,
            allowedLocations: team2AllowedLocations,
            playsAt: team2PlaysAt,
            playsAtTimes: team2PlaysAtTimes,
            playsAtLocations: team2PlaysAtLocations,
            timeNumber: team2TimeNumbers[unchecked: time],
            locationNumber: team2LocationNumbers[unchecked: location],
            maxTimeNumber: maxTeam2TimeNumbers[unchecked: time],
            maxLocationNumber: maxTeam2LocationNumbers[unchecked: location],
            gameGap: gameGap
        )
    }
}

// MARK: Entry
extension LeagueScheduleData {
    /// - Returns: Whether or not a team can play at the given time and location, taking into account their matchup history.
    static func canPlayAt(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        gameGap: GameGap.TupleValue,
        allowedTimes: Set<LeagueTimeIndex>,
        allowedLocations: Set<LeagueLocationIndex>,
        playsAt: PlaysAt.Element,
        playsAtTimes: PlaysAtTimes.Element,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumbers: LeagueAssignedTimes.Element,
        locationNumbers: LeagueAssignedLocations.Element,
        maxTimeNumbers: MaximumTimeAllocations.Element,
        maxLocationNumbers: MaximumLocationAllocations.Element
    ) -> Bool {
        return canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            timeNumber: timeNumbers[unchecked: time],
            locationNumber: locationNumbers[unchecked: location],
            maxTimeNumber: maxTimeNumbers[unchecked: time],
            maxLocationNumber: maxLocationNumbers[unchecked: location],
            gameGap: gameGap
        )
    }

    /// - Returns: Whether or not a team can play at the given time and location, taking into account their matchup history.
    static func canPlayAt(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: Set<LeagueTimeIndex>,
        allowedLocations: Set<LeagueLocationIndex>,
        playsAt: PlaysAt.Element,
        playsAtTimes: PlaysAtTimes.Element,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: LeagueTimeIndex,
        maxLocationNumber: LeagueLocationIndex,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return generalCanPlayAt(
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumber,
            locationNumber: locationNumber,
            maxTimeNumber: maxTimeNumber,
            maxLocationNumber: maxLocationNumber
        )
        && gameGapAllowed(time: time, playsAtTimes: playsAtTimes, gameGap: gameGap)
    }

    static func canPlayAtSameLocationIfB2B(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: Set<LeagueTimeIndex>,
        allowedLocations: Set<LeagueLocationIndex>,
        playsAt: PlaysAt.Element,
        playsAtTimes: PlaysAtTimes.Element,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: LeagueTimeIndex,
        maxLocationNumber: LeagueLocationIndex,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            timeNumber: timeNumber,
            locationNumber: locationNumber,
            maxTimeNumber: maxTimeNumber,
            maxLocationNumber: maxLocationNumber,
            gameGap: gameGap
        )
        && canPlayAtSameLocationIfB2B(
            time: time,
            location: location,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations
        )
    }
}

// MARK: With Travel Durations
extension LeagueScheduleData {
    static func canPlayAtWithTravelDurations(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: Set<LeagueTimeIndex>,
        allowedLocations: Set<LeagueLocationIndex>,
        playsAt: PlaysAt.Element,
        playsAtTimes: PlaysAtTimes.Element,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: LeagueTimeIndex,
        maxLocationNumber: LeagueLocationIndex,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return generalCanPlayAt(
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumber,
            locationNumber: locationNumber,
            maxTimeNumber: maxTimeNumber,
            maxLocationNumber: maxLocationNumber
        )
        && gameGapAndTravelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt,
            gameGap: gameGap
        )
    }
}

// MARK: General
extension LeagueScheduleData {
    static func generalCanPlayAt(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: Set<LeagueTimeIndex>,
        allowedLocations: Set<LeagueLocationIndex>,
        playsAtTimes: PlaysAtTimes.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: LeagueTimeIndex,
        maxLocationNumber: LeagueLocationIndex,
    ) -> Bool {
        return !playsAtTimes.contains(time)
            && allowedTimes.contains(time)
            && allowedLocations.contains(location)
            && timeNumber < maxTimeNumber
            && locationNumber < maxLocationNumber
    }
}

// MARK: Same Location if b2b
extension LeagueScheduleData {
    static func canPlayAtSameLocationIfB2B(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        playsAtTimes: Set<LeagueTimeIndex>,
        playsAtLocations: Set<LeagueLocationIndex>
    ) -> Bool {
        if time > 0 && playsAtTimes.contains(time-1) || playsAtTimes.contains(time+1) {
            // is back-to-back
            return playsAtLocations.contains(location)
        }
        return true
    }
}

// MARK: Game Gap
extension LeagueScheduleData {
    static func gameGapAllowed(
        time: LeagueTimeIndex,
        playsAtTimes: PlaysAtTimes.Element,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        var closest:LeagueTimeIndex? = nil
        for game in playsAtTimes {
            let distance = abs(game.distance(to: time))
            if closest == nil || distance < closest! {
                closest = LeagueTimeIndex(distance)
            }
        }
        var value = true
        if let distance = closest {
            value = gameGapAllowed(distance: distance, gameGap: gameGap)
        }
        return value
    }
    static func gameGapAllowed(
        distance: LeagueTimeIndex,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return distance >= gameGap.min && distance <= gameGap.max
    }
}

// MARK: Travel Duration
extension LeagueScheduleData {
    static func travelDurationAllowed(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        playsAt: Set<LeagueAvailableSlot>
    ) -> Bool {
        var closestSlot:LeagueAvailableSlot? = nil
        for slot in playsAt {
            let distance = abs(slot.time.distance(to: time))
            if closestSlot == nil || distance < closestSlot!.time {
                closestSlot = slot
            }
        }
        guard let closestSlot else { return true }
        return travelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            closestSlot: closestSlot,
            time: time,
            location: location
        )
    }
    static func travelDurationAllowed(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        closestSlot: LeagueAvailableSlot,
        time: LeagueTimeIndex,
        location: LeagueLocationIndex
    ) -> Bool {
        let totalDuration = matchupDuration + travelDurations[unchecked: closestSlot.location][unchecked: location]
        var closestTime = startingTimes[unchecked: closestSlot.time]
        if closestSlot.time < time {
            closestTime.add(totalDuration)
            return closestTime <= startingTimes[unchecked: time]
        } else {
            closestTime.subtract(totalDuration)
            return startingTimes[unchecked: time] <= closestTime
        }
    }
}

// MARK: Game Gap & Travel Duration
extension LeagueScheduleData {
    static func gameGapAndTravelDurationAllowed(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        playsAt: Set<LeagueAvailableSlot>,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        var closestSlot:LeagueAvailableSlot? = nil
        var closestDistance:LeagueTimeIndex? = nil
        for slot in playsAt {
            let distance = abs(slot.time.distance(to: time))
            if closestSlot == nil || distance < closestSlot!.time {
                closestSlot = slot
                closestDistance = LeagueTimeIndex(distance)
            }
        }
        guard let closestSlot, let closestDistance else { return true }
        return gameGapAllowed(distance: closestDistance, gameGap: gameGap)
            && travelDurationAllowed(
                startingTimes: startingTimes,
                matchupDuration: matchupDuration,
                travelDurations: travelDurations,
                closestSlot: closestSlot,
                time: time,
                location: location
            )
    }
}

// MARK: Functions
extension LeagueScheduleData {
    func canPlayAtFunctions() -> (CanPlayAtClosure, OptimizedTeamCanPlayAtClosure) {
        let canPlayAtFunc:CanPlayAtClosure
        let shuffleCanPlayAtFunc:OptimizedTeamCanPlayAtClosure
        if assignmentState.matchupDuration > 0 {
            canPlayAtFunc = Self.canPlayAtWithTravelDurations
            shuffleCanPlayAtFunc = Self.canPlayAt
        } else if sameLocationIfB2B {
            canPlayAtFunc = Self.canPlayAtSameLocationIfB2B
            shuffleCanPlayAtFunc = Self.canPlayAtSameLocationIfB2B
        } else {
            canPlayAtFunc = Self.canPlayAt
            shuffleCanPlayAtFunc = Self.canPlayAt
        }
        return (canPlayAtFunc, shuffleCanPlayAtFunc)
    }
}