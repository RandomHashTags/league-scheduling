
/// - Warning: Only supports a maximum of 128 entries!
/// - Warning: Only supports integers < `128`!
struct BitSet128<Element: FixedWidthInteger & Sendable>: Sendable {
    private(set) var storage:UInt128

    init() {
        storage = 0
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

    func forEachBitWithReturn<Result>(_ yield: (Element) -> Result?) -> Result? {
        var temp = storage
        while temp != 0 {
            let index = temp.trailingZeroBitCount
            if let r = yield(Element(index)) {
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
extension BitSet128: SetOfTimeIndexes where Element == LeagueTimeIndex {}
extension BitSet128: SetOfLocationIndexes where Element == LeagueLocationIndex {}