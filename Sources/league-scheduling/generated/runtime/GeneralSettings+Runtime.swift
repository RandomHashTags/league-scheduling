
import StaticDateTimes

extension LeagueGeneralSettings {
    func runtime() throws(LeagueError) -> Runtime {
        try .init(protobuf: self)
    }

    /// For optimal runtime performance
    struct Runtime: Sendable {
        var gameGap:GameGap
        var timeSlots:LeagueTimeIndex
        var startingTimes:[StaticTime]
        var entriesPerLocation:LeagueEntriesPerMatchup
        var locations:LeagueLocationIndex
        var defaultMaxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay
        var maximumPlayableMatchups:[UInt32]
        var matchupDuration:LeagueMatchupDuration
        var locationTimeExclusivities:[Set<LeagueTimeIndex>]?
        var locationTravelDurations:[[LeagueMatchupDuration]]?
        var balanceTimeStrictness:LeagueBalanceStrictness
        var balancedTimes:Set<LeagueTimeIndex>
        var balanceLocationStrictness:LeagueBalanceStrictness
        var balancedLocations:Set<LeagueLocationIndex>
        var redistributionSettings:LitLeagues_Leagues_RedistributionSettings?
        var flags:UInt32

        init(
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

    var optimizeTimes: Bool {
        isFlag(.optimizeTimes)
    }

    var prioritizeEarlierTimes: Bool {
        isFlag(.prioritizeEarlierTimes)
    }

    var prioritizeHomeAway: Bool {
        isFlag(.prioritizeHomeAway)
    }

    var balanceHomeAway: Bool {
        isFlag(.balanceHomeAway)
    }

    var sameLocationIfB2B: Bool {
        isFlag(.sameLocationIfBackToBack)
    }
}

extension LeagueGeneralSettings.Runtime {
    init(
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
    mutating func computeSettings(
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