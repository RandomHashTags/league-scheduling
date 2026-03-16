
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