
import StaticDateTimes

struct CanPlayAtSameLocationIfB2B: CanPlayAtProtocol, ~Copyable {
    func test(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
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
        return CanPlayAtNormal.test(
            time: time,
            location: location,
            allowedTimes: allowedTimes,
            allowedLocations: allowedLocations,
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumber,
            locationNumber: locationNumber,
            maxTimeNumber: maxTimeNumber,
            maxLocationNumber: maxLocationNumber,
            gameGap: gameGap
        )
        && Self.test(
            time: time,
            location: location,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations
        )
    }

    /// - Returns: If a team with the provided data can play at the given `time` and `location`.
    static func test(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        playsAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        playsAtLocations: borrowing some SetOfLocationIndexes & ~Copyable
    ) -> Bool {
        if time > 0 && playsAtTimes.contains(time-1) || playsAtTimes.contains(time+1) {
            // is back-to-back
            return playsAtLocations.contains(location)
        }
        return true
    }
}