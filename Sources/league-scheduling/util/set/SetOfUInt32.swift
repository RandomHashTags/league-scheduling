
import OrderedCollections

protocol SetOfUInt32: AbstractSet, ~Copyable where Element == UInt32 {}

typealias SetOfDayIndexes = SetOfUInt32
typealias SetOfTimeIndexes = SetOfUInt32
typealias SetOfLocationIndexes = SetOfUInt32

extension Set<UInt32>: SetOfUInt32 {}
extension OrderedSet<UInt32>: SetOfUInt32 {}