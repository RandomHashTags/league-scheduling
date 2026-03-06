
import StaticDateTimes

struct CanPlayAtNormal: CanPlayAtProtocol, ~Copyable {
    /// - Returns: If a team with the provided data can play at the given `time` and `location`.
    /// - Warning: Only checks if the allocations and game gap are allowed.
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
        return Self.test(
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
    }

    /// - Returns: If a team with the provided data can play at the given `time` and `location`.
    /// - Warning: Only checks if the allocations and `gameGap` are allowed.
    static func test(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: some SetOfTimeIndexes,
        allowedLocations: some SetOfLocationIndexes,
        playsAtTimes: PlaysAtTimes.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: UInt8,
        maxLocationNumber: UInt8,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return isAllowed(
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
        && CanPlayAtGameGap.test(time: time, playsAtTimes: playsAtTimes, gameGap: gameGap)
    }

    /// - Returns: If a team with the provided data can play at the given `time` and `location`.
    static func isAllowed(
        time: LeagueTimeIndex,
        location: LeagueLocationIndex,
        allowedTimes: some SetOfTimeIndexes,
        allowedLocations: some SetOfLocationIndexes,
        playsAtTimes: PlaysAtTimes.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: UInt8,
        maxLocationNumber: UInt8
    ) -> Bool {
        return !playsAtTimes.contains(time)
            && allowedTimes.contains(time)
            && allowedLocations.contains(location)
            && timeNumber < maxTimeNumber
            && locationNumber < maxLocationNumber
    }
}