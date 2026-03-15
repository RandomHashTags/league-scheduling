
import StaticDateTimes

// MARK: Initialization
extension LeagueGeneralSettings {
    init(
        gameGap: String,
        timeSlots: LeagueTimeIndex,
        startingTimes: [StaticTime],
        entriesPerLocation: LeagueEntriesPerMatchup,
        locations: LeagueLocationIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32],
        matchupDuration: Double? = nil,
        locationTimeExclusivities: LeagueLocationTimeExclusivities? = nil,
        locationTravelDurations: LeagueLocationTravelDurations? = nil,
        balanceTimeStrictness: LeagueBalanceStrictness,
        balancedTimes: [LeagueTimeIndex],
        balanceLocationStrictness: LeagueBalanceStrictness,
        balancedLocations: [LeagueLocationIndex],
        flags: UInt32
    ) {
        self.gameGap = gameGap
        self.timeSlots = timeSlots
        self.startingTimes = .init(times: startingTimes)
        self.entriesPerLocation = entriesPerLocation
        self.locations = locations
        self.entryMatchupsPerGameDay = entryMatchupsPerGameDay
        self.maximumPlayableMatchups = .init(array: maximumPlayableMatchups)
        if let matchupDuration {
            self.matchupDuration = matchupDuration
        }
        if let locationTimeExclusivities {
            self.locationTimeExclusivities = locationTimeExclusivities
        }
        if let locationTravelDurations {
            self.locationTravelDurations = locationTravelDurations
        }
        self.balanceTimeStrictness = balanceTimeStrictness
        self.balancedTimes = .init(array: balancedTimes)
        self.balanceLocationStrictness = balanceLocationStrictness
        self.balancedLocations = .init(array: balancedLocations)
        self.flags = flags
    }
}

// MARK: General
extension LeagueGeneralSettings {
    func isFlag(_ flag: LeagueSettingFlags) -> Bool {
        flags & UInt32(1 << flag.rawValue) != 0
    }

    /// If we should try arranging matchups so they fit in less time slots than provided.
    var optimizeTimes: Bool {
        isFlag(.optimizeTimes)
    }

    /// If we should try arranging matchups so they fill earlier time slots first.
    var prioritizeEarlierTimes: Bool {
        isFlag(.prioritizeEarlierTimes)
    }

    /// If we should try keeping matchups that play at "home" to play at "home" for later matchups (and the same for "away" matchups).
    var prioritizeHomeAway: Bool {
        isFlag(.prioritizeHomeAway)
    }

    /// If we should try balancing the number each entry plays each other at "home" and "away".
    var balanceHomeAway: Bool {
        isFlag(.balanceHomeAway)
    }

    /// If we should try keeping teams on the same location if they play back-to-back matchups.
    var sameLocationIfB2B: Bool {
        isFlag(.sameLocationIfBackToBack)
    }
}