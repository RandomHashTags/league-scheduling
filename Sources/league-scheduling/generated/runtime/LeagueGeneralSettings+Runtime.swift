
import StaticDateTimes

extension LeagueGeneralSettings {
    public func runtime() throws(LeagueError) -> Runtime {
        try .init(protobuf: self)
    }

    /// For optimal runtime performance
    public struct Runtime: Codable, Sendable {
        public var gameGap:GameGap
        public var timeSlots:LeagueTimeIndex
        public var startingTimes:[StaticTime]
        public var entriesPerLocation:LeagueEntriesPerMatchup
        public var locations:LeagueLocationIndex
        public var defaultMaxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay
        public var maximumPlayableMatchups:[UInt32]
        public var matchupDuration:LeagueMatchupDuration
        public var locationTimeExclusivities:[Set<LeagueTimeIndex>]?
        public var locationTravelDurations:[[LeagueMatchupDuration]]?
        public var balanceTimeStrictness:LeagueBalanceStrictness
        public var balancedTimes:Set<LeagueTimeIndex>
        public var balanceLocationStrictness:LeagueBalanceStrictness
        public var balancedLocations:Set<LeagueLocationIndex>
        public var redistributionSettings:LitLeagues_Leagues_RedistributionSettings?
        public var flags:UInt32

        public init(
            protobuf: LeagueGeneralSettings
        ) throws(LeagueError) {
            guard let gameGap = GameGap(htmlInputValue: protobuf.gameGap) else {
                throw .malformedInput(msg: "invalid GameGap htmlInputValue: \(protobuf.gameGap)")
            }
            self.gameGap = gameGap
            timeSlots = protobuf.timeSlots
            startingTimes = protobuf.startingTimes.times
            entriesPerLocation = protobuf.entriesPerLocation
            locations = protobuf.locations
            defaultMaxEntryMatchupsPerGameDay = protobuf.entryMatchupsPerGameDay
            maximumPlayableMatchups = protobuf.maximumPlayableMatchups.array
            matchupDuration = protobuf.matchupDuration
            if protobuf.hasLocationTimeExclusivities {
                locationTimeExclusivities = protobuf.locationTimeExclusivities.locations.map({ Set($0.times) })
            } else {
                locationTimeExclusivities = nil
            }
            if protobuf.hasLocationTravelDurations {
                locationTravelDurations = protobuf.locationTravelDurations.locations.map({ $0.travelDurationTo })
            } else {
                locationTravelDurations = nil
            }
            balanceTimeStrictness = protobuf.balanceTimeStrictness
            balancedTimes = Set(protobuf.balancedTimes.array)
            balanceLocationStrictness = protobuf.balanceLocationStrictness
            balancedLocations = Set(protobuf.balancedLocations.array)
            if protobuf.hasRedistributionSettings {
                redistributionSettings = protobuf.redistributionSettings
            } else {
                redistributionSettings = nil
            }
            flags = protobuf.flags
        }
    }
}

// MARK: Flags
extension LeagueGeneralSettings.Runtime {
    func isFlag(_ flag: LeagueSettingFlags) -> Bool {
        flags & UInt32(1 << flag.rawValue) != 0
    }

    public var optimizeTimes: Bool {
        isFlag(.optimizeTimes)
    }

    public var prioritizeEarlierTimes: Bool {
        isFlag(.prioritizeEarlierTimes)
    }

    public var prioritizeHomeAway: Bool {
        isFlag(.prioritizeHomeAway)
    }

    public var balanceHomeAway: Bool {
        isFlag(.balanceHomeAway)
    }

    public var sameLocationIfB2B: Bool {
        isFlag(.sameLocationIfBackToBack)
    }
}

extension LeagueGeneralSettings.Runtime {
    public init(
        gameGap: GameGap,
        timeSlots: LeagueTimeIndex,
        startingTimes: [StaticTime],
        entriesPerLocation: LeagueEntriesPerMatchup,
        locations: LeagueLocationIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32],
        matchupDuration: LeagueMatchupDuration,
        locationTimeExclusivities: [Set<LeagueTimeIndex>]?,
        locationTravelDurations: [[LeagueMatchupDuration]]?,
        balanceTimeStrictness: LeagueBalanceStrictness,
        balancedTimes: Set<LeagueTimeIndex>,
        balanceLocationStrictness: LeagueBalanceStrictness,
        balancedLocations: Set<LeagueLocationIndex>,
        redistributionSettings: LitLeagues_Leagues_RedistributionSettings?,
        flags: UInt32
    ) {
        self.gameGap = gameGap
        self.timeSlots = timeSlots
        self.startingTimes = startingTimes
        self.entriesPerLocation = entriesPerLocation
        self.locations = locations
        self.defaultMaxEntryMatchupsPerGameDay = entryMatchupsPerGameDay
        self.maximumPlayableMatchups = maximumPlayableMatchups
        self.matchupDuration = matchupDuration
        self.locationTimeExclusivities = locationTimeExclusivities
        self.locationTravelDurations = locationTravelDurations
        self.balanceTimeStrictness = balanceTimeStrictness
        self.balancedTimes = balancedTimes
        self.balanceLocationStrictness = balanceLocationStrictness
        self.balancedLocations = balancedLocations
        self.redistributionSettings = redistributionSettings
        self.flags = flags
    }
}

// MARK: Compute settings
extension LeagueGeneralSettings.Runtime {
    /// Modifies `timeSlots` and `startingTimes` taking into account current settings.
    public mutating func computeSettings(
        day: LeagueDayIndex,
        entries: [LeagueEntry.Runtime]
    ) {
        if optimizeTimes {
            var maxMatchupsPlayedToday:LeagueLocationIndex = 0
            for entry in entries {
                if entry.gameDays.contains(day) && !entry.byes.contains(day) {
                    maxMatchupsPlayedToday += entry.maxMatchupsForGameDay(day: day, fallback: defaultMaxEntryMatchupsPerGameDay)
                }
            }
            maxMatchupsPlayedToday /= entriesPerLocation
            let filledTimeSlots = LeagueSchedule.optimalTimeSlots(
                availableTimeSlots: timeSlots,
                locations: locations,
                matchupsCount: maxMatchupsPlayedToday
            )
            while filledTimeSlots < timeSlots {
                timeSlots -= 1
            }
            while filledTimeSlots < startingTimes.count {
                startingTimes.removeLast()
            }
        }
    }
}