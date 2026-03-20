
import StaticDateTimes

/// Optimized storage that tests whether a team can play at a given `time` and `location` based on its current assignment data and `gameGap`.
protocol CanPlayAtProtocol: Sendable, ~Copyable {
    func test(
        time: TimeIndex,
        location: LocationIndex,
        allowedTimes: Set<TimeIndex>,
        allowedLocations: Set<LocationIndex>,
        playsAt: borrowing some SetOfAvailableSlots & ~Copyable,
        playsAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        playsAtLocations: PlaysAtLocations.Element,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: UInt8,
        maxLocationNumber: UInt8,
        gameGap: GameGap.TupleValue
    ) -> Bool
}