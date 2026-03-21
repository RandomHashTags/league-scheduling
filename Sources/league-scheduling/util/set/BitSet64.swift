
/// - Warning: Only supports a maximum of 64 entries!
/// - Warning: Only supports integers < `64`!
struct BitSet64<Element: FixedWidthInteger & Sendable>: Sendable {
    private(set) var storage:UInt64

    init() {
        storage = 0
    }
    init(minimumCapacity: Int) {
        storage = 0
    }

    init(storage: UInt64) {
        self.storage = storage
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

    func reserveCapacity(_ minimumCapacity: Int) {
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
extension BitSet64 {
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
    func randomElement(using: inout some RandomNumberGenerator) -> Element? {
        guard storage != 0 else { return nil }
        let skip = Int.random(in: 0..<count, using: &using)
        var temp = storage
        for _ in 0..<skip {
            temp &= temp - 1
        }
        return Element(temp.trailingZeroBitCount)
    }
}

// MARK: AbstractSet
extension BitSet64: AbstractSet {
    func filter(_ closure: (Element) throws -> Bool) rethrows -> Self {
        var temp = UInt64(0)
        try forEach { i in
            if try closure(i) {
                temp |= 1 << i
            }
        }
        return .init(storage: temp)
    }

    var first: Element? {
        let e = storage.trailingZeroBitCount
        guard e > 0 else { return nil }
        return 1 << e
    }

    func first(where condition: (Element) throws -> Bool) rethrows -> Element? {
        return try forEachWithReturn { i in
            if try condition(i) {
                return 1 << i
            }
            return nil
        }
    }

    func map<Result>(_ body: (Element) throws -> Result) rethrows -> [Result] {
        var array = [Result]()
        array.reserveCapacity(count)
        try forEach {
            try array.append(body($0))
        }
        return array
    }

    func intersection(_ other: borrowing Self) -> Self  {
        return .init(storage: storage & other.storage)
    }
}
extension BitSet64: SetOfUInt32 where Element == UInt32 {}

extension BitSet64: SetOfEntryIDs where Element == Entry.IDValue {
    func availableMatchupPairs<MatchupPairSet: AbstractSet>(
        assignedEntryHomeAways: AssignedEntryHomeAways,
        maxSameOpponentMatchups: MaximumSameOpponentMatchups
    ) -> MatchupPairSet where MatchupPairSet.Element == MatchupPair {
        var pairs = MatchupPairSet(minimumCapacity: (count-1) * 2)
        forEach { home in
            let assignedHome = assignedEntryHomeAways[unchecked: home]
            let maxSameOpponentMatchups = maxSameOpponentMatchups[unchecked: home]
            forEach { away in
                if away > home, assignedHome[unchecked: away].sum < maxSameOpponentMatchups[unchecked: away] {
                    pairs.insertMember(.init(team1: home, team2: away))
                }
            }
        }
        return pairs
    }
}