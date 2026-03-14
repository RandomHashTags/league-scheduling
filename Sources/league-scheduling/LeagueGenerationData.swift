
public struct LeagueGenerationData: Sendable {
    public var error:LeagueError? = nil
    public var assignLocationTimeRegenerationAttempts:UInt32 = 0
    public var negativeDayIndexRegenerationAttempts:UInt32 = 0
    public var schedule:ContiguousArray<Set<LitLeagues_Leagues_Matchup>> = []

    #if UnitTesting
    /// Number of times an entry was assigned to a given time.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [`LeagueTimeIndex`: `amount played at LeagueTimeIndex`]
    public var assignedTimes = LeagueAssignedTimes()

    /// Number of times an entry was assigned to a given location.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `amount played at LeagueLocationIndex`]]
    public var assignedLocations = LeagueAssignedLocations()

    /// Number of times an entry was assigned to play at home or away against another entry.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: [`home (0) or away (1)`: `total played`]]]
    public var assignedEntryHomeAways:ContiguousArray<ContiguousArray<LeagueSchedule.HomeAwayValue>> = []

    /// Number of times an entry was assigned to play at home or away.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [`home (0) or away (1)`: `total played`] ]
    public var assignedHomeAways:ContiguousArray<ContiguousArray<UInt8>> = []

    /// Maximum number of allocations allowed for a given entry for a given time. Zero indicates infinite.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [`LeagueTimeIndex`: `maximum allowed at LeagueTimeIndex`]]
    public var maxTimeAllocations:ContiguousArray<ContiguousArray<LeagueTimeIndex>> = []

    /// Maximum number of allocations allowed for a given entry for a given location. Zero indicates infinite.
    /// 
    /// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `maximum allowed at LeagueLocationIndex`]]
    public var maxLocationAllocations:ContiguousArray<ContiguousArray<LeagueLocationIndex>> = []
    #endif

    public var executionSteps = [ExecutionStep]()
    public var shuffleHistory = [LeagueShuffleAction]()

    func scheduleSorted() -> ContiguousArray<[LeagueMatchup]> {
        var array:ContiguousArray<[LeagueMatchup]> = .init(repeating: [], count: schedule.count)
        for (dayIndex, matchups) in schedule.enumerated() {
            array[unchecked: dayIndex] = matchups.sorted(by: {
                guard $0.time == $1.time else { return $0.time < $1.time }
                return $0.location < $1.location
            })
        }
        return array
    }
}

// MARK: Codable
extension LeagueGenerationData: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assignLocationTimeRegenerationAttempts, forKey: .assignLocationTimeRegenerationAttempts)
        try container.encode(negativeDayIndexRegenerationAttempts, forKey: .negativeDayIndexRegenerationAttempts)
        try container.encode(scheduleSorted(), forKey: .schedule)

        #if UnitTesting
        try container.encode(assignedTimes, forKey: .assignedTimes)
        try container.encode(assignedLocations, forKey: .assignedLocations)
        try container.encode(assignedEntryHomeAways, forKey: .assignedEntryHomeAways)
        try container.encode(assignedHomeAways, forKey: .assignedHomeAways)
        try container.encode(maxTimeAllocations, forKey: .maxTimeAllocations)
        try container.encode(maxLocationAllocations, forKey: .maxLocationAllocations)
        #endif

        try container.encode(executionSteps, forKey: .executionSteps)
        try container.encode(shuffleHistory, forKey: .shuffleHistory)
    }
}

// MARK: CodingKeys
extension LeagueGenerationData {
    enum CodingKeys: CodingKey {
        case assignLocationTimeRegenerationAttempts
        case negativeDayIndexRegenerationAttempts
        case schedule
        case executionSteps
        case shuffleHistory

        #if UnitTesting
        case assignedTimes
        case assignedLocations
        case assignedEntryHomeAways
        case assignedHomeAways
        case maxTimeAllocations
        case maxLocationAllocations
        #endif
    }
}