
/// - Warning: Only supports a maximum of 64 entries!
/// - Warning: Only supports integers < `64`!
struct BitSet64<Element: FixedWidthInteger & Sendable>: Sendable {
    private(set) var storage:UInt64

    init() {
        storage = 0
    }

    init(_ collection: some Collection<Element>) {
        storage = 0
        for e in collection {
            insertMember(e)
        }
    }
    init<T: AbstractSet>(_ set: T) where T.Element == Element {
        storage = 0
        set.forEach {
            insertMember($0)
        }
    }

    var count: Int {
        storage.nonzeroBitCount
    }

    var isEmpty: Bool {
        storage == 0
    }
}

// MARK: contains
extension BitSet64 {
    func contains(_ member: Element) -> Bool {
        (storage & (1 << member)) != 0
    }
}

// MARK: insert
extension BitSet64 {
    mutating func insertMember(_ member: Element) {
        storage |= (1 << member)
    }
}

// MARK: remove
extension BitSet64 {
    mutating func removeMember(_ member: Element) {
        storage &= ~(1 << member)
    }
}

// MARK: remove all
extension BitSet64 {
    mutating func removeAll() {
        storage = 0
    }
}

// MARK: iterator
extension BitSet64 {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        var temp = storage
        while temp != 0 {
            let index = temp.trailingZeroBitCount
            try body(Element(index))
            temp &= (temp - 1)
        }
    }
}

// MARK: form union
extension BitSet64 {
    mutating func formUnion(_ bitSet: Self) {
        storage |= bitSet.storage
    }
}

// MARK: Random
extension BitSet64 {
    func randomElement() -> Element? {
        guard storage != 0 else { return nil }
        let skip = Int.random(in: 0..<count)
        var temp = storage
        for _ in 0..<skip {
            temp &= temp - 1
        }
        return Element(temp.trailingZeroBitCount)
    }
}

// MARK: AbstractSet
extension BitSet64: AbstractSet {}
extension BitSet64: SetOfTimeIndexes where Element == LeagueTimeIndex {}
extension BitSet64: SetOfLocationIndexes where Element == LeagueLocationIndex {}