
/// - Warning: Only supports a maximum of 128 entries!
/// - Warning: Only supports integers < `128`!
struct BitSet128<Element: FixedWidthInteger & Sendable>: Sendable {
    private(set) var storage:UInt128

    init() {
        storage = 0
    }

    init(storage: UInt128) {
        self.storage = storage
    }

    init(_ collection: some Collection<Element>) {
        storage = 0
        for e in collection {
            insertMember(e)
        }
    }

    var count: Int {
        storage.nonzeroBitCount
    }

    var isEmpty: Bool {
        storage == 0
    }

    func reserveCapacity(_ minimumCapacity: Int) {
    }
}

// MARK: contains
extension BitSet128 {
    func contains(_ member: Element) -> Bool {
        (storage & (1 << member)) != 0
    }
}

// MARK: insert
extension BitSet128 {
    mutating func insertMember(_ member: Element) {
        storage |= (1 << member)
    }
}

// MARK: remove
extension BitSet128 {
    mutating func removeMember(_ member: Element) {
        storage &= ~(1 << member)
    }
}

// MARK: remove all
extension BitSet128 {
    mutating func removeAll() {
        storage = 0
    }
    mutating func removeAllKeepingCapacity() {
        storage = 0
    }
    mutating func removeAll(where condition: (Element) throws -> Bool) rethrows {
        try forEach {
            if try condition($0) {
                removeMember($0)
            }
        }
    }
}

// MARK: iterator
extension BitSet128 {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        var temp = storage
        while temp != 0 {
            let index = temp.trailingZeroBitCount
            try body(Element(index))
            temp &= (temp - 1)
        }
    }
    func forEachWithReturn<Result>(_ body: (Element) throws -> Result?) rethrows -> Result? {
        var temp = storage
        while temp != 0 {
            let index = temp.trailingZeroBitCount
            if let r = try body(Element(index)) {
                return r
            }
            temp &= (temp - 1)
        }
        return nil
    }
}

// MARK: form union
extension BitSet128 {
    mutating func formUnion(_ bitSet: Self) {
        storage |= bitSet.storage
    }
}

// MARK: Random
extension BitSet128 {
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
extension BitSet128: AbstractSet {}
extension BitSet128: SetOfUInt32 where Element == UInt32 {}

extension BitSet128: SetOfEntryIDs where Element == Entry.IDValue {
    func availableMatchupPairs(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> Set<MatchupPair> {
        var pairs = Set<MatchupPair>(minimumCapacity: (count-1) * 2)
        forEach { home in
            let assignedHome = assignedEntryHomeAways[unchecked: home]
            let maxSameOpponentMatchups = maxSameOpponentMatchups[unchecked: home]
            forEach { away in
                if away > home, assignedHome[unchecked: away].sum < maxSameOpponentMatchups[unchecked: away] {
                    pairs.insert(.init(team1: home, team2: away))
                }
            }
        }
        return pairs
    }
}