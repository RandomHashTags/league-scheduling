
import OrderedCollections

protocol SetOfMatchupPair: AbstractSet, ~Copyable where Element == MatchupPair {
}

extension Set<MatchupPair>: SetOfMatchupPair {}
extension OrderedSet<MatchupPair>: SetOfMatchupPair {}