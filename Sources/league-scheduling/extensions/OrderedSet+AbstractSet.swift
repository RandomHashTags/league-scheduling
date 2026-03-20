
import OrderedCollections

extension OrderedSet: AbstractSet {
    init(minimumCapacity: Int) {
        self.init()
        reserveCapacity(minimumCapacity)
    }

    @inline(__always)
    mutating func removeMember(_ member: Element) {
        self.remove(member)
    }

    @inline(__always)
    mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }
    @inline(__always)
    mutating func removeAllKeepingCapacity() {
        self.removeAll(keepingCapacity: true)
    }

    func forEachWithReturn<Result>(_ body: (Element) throws -> Result?) rethrows -> Result? {
        for e in self {
            if let r = try body(e) {
                return r
            }
        }
        return nil
    }

    @inline(__always)
    mutating func insertMember(_ member: Element) {
        append(member)
    }
}