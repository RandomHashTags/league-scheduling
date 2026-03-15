
public struct LeagueGenerationData: Sendable {
    public var error:LeagueError? = nil
    public var assignLocationTimeRegenerationAttempts:UInt32 = 0
    public var negativeDayIndexRegenerationAttempts:UInt32 = 0
    public var schedule:ContiguousArray<Set<LitLeagues_Leagues_Matchup>> = []
    public var executionSteps = [ExecutionStep]()
    public var shuffleHistory = [LeagueShuffleAction]()
}

#if ProtobufCodable
// MARK: Codable
extension LeagueGenerationData: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assignLocationTimeRegenerationAttempts, forKey: .assignLocationTimeRegenerationAttempts)
        try container.encode(negativeDayIndexRegenerationAttempts, forKey: .negativeDayIndexRegenerationAttempts)
        try container.encode(scheduleSorted(), forKey: .schedule)
        try container.encode(executionSteps, forKey: .executionSteps)
        try container.encode(shuffleHistory, forKey: .shuffleHistory)
    }

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

    enum CodingKeys: CodingKey {
        case assignLocationTimeRegenerationAttempts
        case negativeDayIndexRegenerationAttempts
        case schedule
        case executionSteps
        case shuffleHistory
    }
}
#endif