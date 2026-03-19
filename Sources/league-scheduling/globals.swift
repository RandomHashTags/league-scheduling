
import OrderedCollections

// MARK: adjacent times
func calculateAdjacentTimes(
    for time: TimeIndex,
    entryMatchupsPerGameDay: EntryMatchupsPerGameDay
) -> OrderedSet<TimeIndex> {
    var adjacentTimes = OrderedSet<TimeIndex>()
    let timeIndex = time % entryMatchupsPerGameDay
    if timeIndex == 0 {
        for i in 1..<TimeIndex(entryMatchupsPerGameDay) {
            adjacentTimes.append(time + i)
        }
    } else {
        for i in 1..<timeIndex+1 {
            adjacentTimes.append(time - i)
        }
        if timeIndex < entryMatchupsPerGameDay-1 {
            for i in 1..<entryMatchupsPerGameDay - timeIndex {
                adjacentTimes.append(time + i)
            }
        }
    }
    return adjacentTimes
}