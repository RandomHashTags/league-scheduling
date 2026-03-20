
import OrderedCollections

protocol SetOfAvailableSlots: AbstractSet, ~Copyable where Element == AvailableSlot {
}

extension Set<AvailableSlot>: SetOfAvailableSlots {}
extension OrderedSet<AvailableSlot>: SetOfAvailableSlots {}