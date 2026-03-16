
#if canImport(SwiftGlibc)
import SwiftGlibc
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: optimal time slots
func optimalTimeSlots(
    availableTimeSlots: TimeIndex,
    locations: LocationIndex,
    matchupsCount: LocationIndex
) -> TimeIndex {
    var totalMatchupsPlayed:LocationIndex = 0
    var filledTimes:TimeIndex = 0
    while totalMatchupsPlayed < matchupsCount {
        filledTimes += 1
        totalMatchupsPlayed += locations
    }
    #if LOG
    print("LeagueSchedule;optimalTimeSlots;availableTimeSlots=\(availableTimeSlots);locations=\(locations);matchupsCount=\(matchupsCount);totalMatchupsPlayed=\(totalMatchupsPlayed);filledTimes=\(filledTimes)")
    #endif
    return min(availableTimeSlots, filledTimes)
}

// MARK: adjacent times
func calculateAdjacentTimes<TimeSet: SetOfTimeIndexes>(
    for time: TimeIndex,
    entryMatchupsPerGameDay: EntryMatchupsPerGameDay
) -> TimeSet {
    var adjacentTimes = TimeSet()
    let timeIndex = time % entryMatchupsPerGameDay
    if timeIndex == 0 {
        for i in 1..<TimeIndex(entryMatchupsPerGameDay) {
            adjacentTimes.insertMember(time + i)
        }
    } else {
        for i in 1..<timeIndex+1 {
            adjacentTimes.insertMember(time - i)
        }
        if timeIndex < entryMatchupsPerGameDay-1 {
            for i in 1..<entryMatchupsPerGameDay - timeIndex {
                adjacentTimes.insertMember(time + i)
            }
        }
    }
    return adjacentTimes
}

// MARK: balance numbers
func calculateBalanceNumber<T: FixedWidthInteger>(
    totalMatchupsPlayed: some FixedWidthInteger,
    value: some FixedWidthInteger,
    strictness: BalanceStrictness
) -> T {
    guard strictness != .lenient else { return .max }
    var minimumValue = T(ceil(Double(totalMatchupsPlayed) / Double(value)))
    switch strictness {
    case .lenient:      minimumValue = .max
    case .normal:       minimumValue += 1
    case .relaxed:      minimumValue += 2
    case .very:         break
    case .UNRECOGNIZED: break
    }
    return minimumValue
}

// MARK: maximum same opponent matchups cap
func calculateMaximumSameOpponentMatchupsCap(
    gameDays: DayIndex,
    entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
    entriesCount: Int
) throws(LeagueError) -> MaximumSameOpponentMatchupsCap {
    guard entriesCount > 1 else {
        throw .malformedInput(msg: "Number of teams need to be > 1 when calculating maximum same opponent matchups cap; got \(entriesCount)")
    }
    return MaximumSameOpponentMatchupsCap(
        ceil(
            Double(gameDays) / (Double(entriesCount-1) / Double(entryMatchupsPerGameDay))
        )
    )
}