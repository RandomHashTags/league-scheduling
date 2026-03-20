
import OrderedCollections

protocol SetOfMatchup: AbstractSet, ~Copyable where Element == Matchup {
}

extension Set<Matchup>: SetOfMatchup {}
extension OrderedSet<Matchup>: SetOfMatchup {}