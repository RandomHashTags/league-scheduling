
// MARK: adjacent times
func calculateAdjacentTimes(
    for time: TimeIndex,
    entryMatchupsPerGameDay: EntryMatchupsPerGameDay
) -> Set<TimeIndex> {
    var adjacentTimes = Set<TimeIndex>()
    let timeIndex = time % entryMatchupsPerGameDay
    if timeIndex == 0 {
        for i in 1..<TimeIndex(entryMatchupsPerGameDay) {
            adjacentTimes.insert(time + i)
        }
    } else {
        for i in 1..<timeIndex+1 {
            adjacentTimes.insert(time - i)
        }
        if timeIndex < entryMatchupsPerGameDay-1 {
            for i in 1..<entryMatchupsPerGameDay - timeIndex {
                adjacentTimes.insert(time + i)
            }
        }
    }
    return adjacentTimes
}