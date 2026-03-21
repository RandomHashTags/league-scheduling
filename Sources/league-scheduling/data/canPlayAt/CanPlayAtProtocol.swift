
import StaticDateTimes

/// Optimized storage that tests whether a team can play at a given `time` and `location` based on its current assignment data and `gameGap`.
protocol CanPlayAtProtocol: Sendable, ~Copyable {
    func test(
        time: TimeIndex,
        location: LocationIndex,
        allowedTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        allowedLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        playsAt: borrowing some SetOfAvailableSlots & ~Copyable,
        playsAtTimes: borrowing some SetOfTimeIndexes & ~Copyable,
        playsAtLocations: borrowing some SetOfLocationIndexes & ~Copyable,
        timeNumber: UInt8,
        locationNumber: UInt8,
        maxTimeNumber: UInt8,
        maxLocationNumber: UInt8,
        gameGap: GameGap.TupleValue
    ) -> Bool
}