
import StaticDateTimes

struct CanPlayAtWithTravelDurations: CanPlayAtProtocol, ~Copyable {
    let startingTimes:[StaticTime]
    let matchupDuration:MatchupDuration
    let travelDurations:[[MatchupDuration]]

    func test(
        time: TimeIndex,
        location: LocationIndex,
        allowedTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        allowedLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        playsAt: PlaysAt.Element,
        playsAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        playsAtLocations: borrowing some SetOfLocationIndexes & ~Copyable,
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
        matchupDuration: MatchupDuration,
        travelDurations: [[MatchupDuration]],
        time: TimeIndex,
        location: LocationIndex,
        playsAt: PlaysAt.Element,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        var closestSlot:AvailableSlot? = nil
        var closestDistance:TimeIndex? = nil
        for slot in playsAt {
            let distance = abs(slot.time.distance(to: time))
            if closestSlot == nil || distance < closestSlot!.time {
                closestSlot = slot
                closestDistance = TimeIndex(distance)
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
        matchupDuration: MatchupDuration,
        travelDurations: [[MatchupDuration]],
        closestSlot: AvailableSlot,
        time: TimeIndex,
        location: LocationIndex
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