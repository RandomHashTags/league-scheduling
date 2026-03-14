

// MARK: Codable
extension LeagueAvailableSlot: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(LeagueTimeIndex.self, forKey: .time)
        location = try container.decode(LeagueLocationIndex.self, forKey: .location)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(location, forKey: .location)
    }

    enum CodingKeys: CodingKey {
        case time
        case location
    }
}

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