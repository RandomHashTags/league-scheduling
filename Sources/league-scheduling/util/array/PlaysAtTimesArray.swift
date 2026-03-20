
struct PlaysAtTimesArray<TimeSet: SetOfTimeIndexes>: Sendable {
    internal private(set) var times:ContiguousArray<TimeSet>

    subscript(unchecked index: some FixedWidthInteger) -> TimeSet {
        times[unchecked: index]
    }

    mutating func removeAllKeepingCapacity() {
        for i in 0..<times.count {
            times[unchecked: i].removeAllKeepingCapacity()
        }
    }

    mutating func insertMember(entryID: Entry.IDValue, member: TimeIndex) {
        times[unchecked: entryID].insertMember(member)
    }

    mutating func removeMember(entryID: Entry.IDValue, member: TimeIndex) {
        times[unchecked: entryID].removeMember(member)
    }
}