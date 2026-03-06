
/// - Warning: Only supports a maximum of 128 entries!
/// - Warning: Only supports integers < `128`!
public struct BitSet128<Element: FixedWidthInteger & Sendable>: Sendable {
    private(set) var storage:UInt128

    public init() {
        storage = 0
    }

    public init(_ collection: some Collection<Element>) {
        storage = 0
        for e in collection {
            insertMember(e)
        }
    }

    public var count: Int {
        storage.nonzeroBitCount
    }
    public var isEmpty: Bool {
        count == 0
    }
}

// MARK: contains
extension BitSet128 {
    public func contains(_ member: Element) -> Bool {
        (storage & (1 << member)) != 0
    }
}

// MARK: insert
extension BitSet128 {
    public mutating func insertMember(_ member: Element) {
        storage |= (1 << member)
    }
}

// MARK: remove
extension BitSet128 {
    public mutating func removeMember(_ member: Element) {
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
    func forEachBit(_ yield: (Element) -> Void) {
        var temp = storage
        while temp != 0 {
            let index = temp.trailingZeroBitCount
            yield(Element(index))
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
        let c = count
        guard c > 0 else { return nil }
        return Element.random(in: 0..<Element(c))
    }
}

// MARK: Codable
extension BitSet128: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = try container.decode(UInt128.self)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}

// MARK: AbstractSet
extension BitSet128: AbstractSet {}
extension BitSet128: SetOfTimeIndexes where Element == LeagueTimeIndex {}
extension BitSet128: SetOfLocationIndexes where Element == LeagueLocationIndex {}