
// MARK: CustomStringConvertible
extension LeagueAvailableSlot: CustomStringConvertible {
    public var description: String {
        "T\(time)L\(location)"
    }
}

// MARK: Hashable
extension LeagueAvailableSlot: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(time)
        hasher.combine(location)
    }
}

// MARK: General
extension LeagueAvailableSlot {
    init(time: LeagueTimeIndex, location: LeagueLocationIndex) {
        self.time = time
        self.location = location
    }
}