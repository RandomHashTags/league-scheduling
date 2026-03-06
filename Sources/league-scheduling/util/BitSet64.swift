
/// - Warning: Only supports a maximum of 64 entries!
/// - Warning: Only supports integers < `64`!
public struct BitSet64<Element: FixedWidthInteger & Sendable>: Hashable, Sendable {
    private(set) var storage:UInt64

    public init() {
        storage = 0
    }

    public init(_ collection: some Collection<Element>) {
        storage = 0
        for e in collection {
            insert(e)
        }
    }

    var count: Int {
        storage.nonzeroBitCount
    }
    var isEmpty: Bool {
        count == 0
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
    mutating func insert(_ member: Element) {
        storage |= (1 << member)
    }
}

// MARK: remove
extension BitSet64 {
    mutating func remove(_ member: Element) {
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
extension BitSet64 {
    mutating func formUnion(_ bitSet: Self) {
        storage |= bitSet.storage
    }
}

// MARK: Random
extension BitSet64 {
    func randomElement() -> Element? {
        return nil // TODO: fix
    }
}

// MARK: Codable
extension BitSet64: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = try container.decode(UInt64.self)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}