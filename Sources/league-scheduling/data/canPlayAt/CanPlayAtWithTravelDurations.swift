
import StaticDateTimes

struct CanPlayAtWithTravelDurations: CanPlayAtProtocol, ~Copyable {
    let startingTimes:[StaticTime]
    let matchupDuration:LeagueMatchupDuration
    let travelDurations:[[LeagueMatchupDuration]]

    func test(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: some SetOfTimeIndexes,
        allowedLocations: some SetOfLocationIndexes,
        playsAt: PlaysAt.Element,
        playsAtTimes: PlaysAtTimes.Element,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: UInt8,
        maxLocationNumber: UInt8,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return CanPlayAtNormal.isAllowed(
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumber,
            locationNumber: locationNumber,
            maxTimeNumber: maxTimeNumber,
            maxLocationNumber: maxLocationNumber
        ) && Self.test(
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

extension CanPlayAtWithTravelDurations {
    /// - Returns: If a matchup can play at the given `time` and `location` taking into account the provided data.
    static func test(
        startingTimes: [StaticTime],
        matchupDuration: LeagueMatchupDuration,
        travelDurations: [[LeagueMatchupDuration]],
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        playsAt: PlaysAt.Element,
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
        return CanPlayAtGameGap.gameGapIsAllowed(distance: closestDistance, gameGap: gameGap)
            && isAllowed(
                startingTimes: startingTimes,
                matchupDuration: matchupDuration,
                travelDurations: travelDurations,
                closestSlot: closestSlot,
                time: time,
                location: location
            )
    }

    /// - Returns: If a matchup can play at the given `time` and `location` taking into account the provided data.
    static func isAllowed(
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