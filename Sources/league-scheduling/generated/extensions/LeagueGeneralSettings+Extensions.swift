
import StaticDateTimes

// MARK: Codable
extension LeagueGeneralSettings: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(String.self, forKey: .gameGap) {
            gameGap = v
        }
        if let v = try container.decodeIfPresent(LeagueTimeIndex.self, forKey: .timeSlots) {
            timeSlots = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_StaticTimes.self, forKey: .startingTimes) {
            startingTimes = v
        }
        if let v = try container.decodeIfPresent(LeagueEntriesPerMatchup.self, forKey: .entriesPerLocation) {
            entriesPerLocation = v
        }
        if let v = try container.decodeIfPresent(LeagueLocationIndex.self, forKey: .locations) {
            locations = v
        }
        if let v = try container.decodeIfPresent(LeagueEntryMatchupsPerGameDay.self, forKey: .entryMatchupsPerGameDay) {
            entryMatchupsPerGameDay = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_UInt32Array.self, forKey: .maximumPlayableMatchups) {
            maximumPlayableMatchups = v
        }
        if let v = try container.decodeIfPresent(LeagueMatchupDuration.self, forKey: .matchupDuration) {
            matchupDuration = v
        }
        if let v = try container.decodeIfPresent(LeagueLocationTimeExclusivities.self, forKey: .locationTimeExclusivities) {
            locationTimeExclusivities = v
        }
        if let v = try container.decodeIfPresent(LeagueLocationTravelDurations.self, forKey: .locationTravelDurations) {
            locationTravelDurations = v
        }
        if let v = try container.decodeIfPresent(LeagueBalanceStrictness.self, forKey: .balanceTimeStrictness) {
            balanceTimeStrictness = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_UInt32Array.self, forKey: .balancedTimes) {
            balancedTimes = v
        }
        if let v = try container.decodeIfPresent(LeagueBalanceStrictness.self, forKey: .balanceLocationStrictness) {
            balanceLocationStrictness = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_UInt32Array.self, forKey: .balancedLocations) {
            balancedLocations = v
        }
        if let v = try container.decodeIfPresent(LitLeagues_Leagues_RedistributionSettings.self, forKey: .redistributionSettings) {
            redistributionSettings = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .flags) {
            flags = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasGameGap {
            try container.encode(gameGap, forKey: .gameGap)
        }
        if hasTimeSlots {
            try container.encode(timeSlots, forKey: .timeSlots)
        }
        if hasStartingTimes {
            try container.encode(startingTimes, forKey: .startingTimes)
        }
        if hasEntriesPerLocation {
            try container.encode(entriesPerLocation, forKey: .entriesPerLocation)
        }
        if hasLocations {
            try container.encode(locations, forKey: .locations)
        }
        if hasEntryMatchupsPerGameDay {
            try container.encode(entryMatchupsPerGameDay, forKey: .entryMatchupsPerGameDay)
        }
        try container.encode(maximumPlayableMatchups, forKey: .maximumPlayableMatchups)
        if hasMatchupDuration {
            try container.encode(matchupDuration, forKey: .matchupDuration)
        }
        if hasLocationTimeExclusivities {
            try container.encode(locationTimeExclusivities, forKey: .locationTimeExclusivities)
        }
        if hasLocationTravelDurations {
            try container.encode(locationTravelDurations, forKey: .locationTravelDurations)
        }
        if hasBalanceTimeStrictness {
            try container.encode(balanceTimeStrictness, forKey: .balanceTimeStrictness)
        }
        if hasBalancedTimes {
            try container.encode(balancedTimes, forKey: .balancedTimes)
        }
        if hasBalanceLocationStrictness {
            try container.encode(balanceLocationStrictness, forKey: .balanceLocationStrictness)
        }
        if hasBalancedLocations {
            try container.encode(balancedLocations, forKey: .balancedLocations)
        }
        if hasRedistributionSettings {
            try container.encode(redistributionSettings, forKey: .redistributionSettings)
        }
        if hasFlags {
            try container.encode(flags, forKey: .flags)
        }
    }

    public enum CodingKeys: CodingKey {
        case gameGap
        case entriesPerLocation
        case timeSlots
        case startingTimes
        case locations
        case entryMatchupsPerGameDay
        case maximumPlayableMatchups
        case matchupDuration
        case locationTimeExclusivities
        case locationTravelDurations
        case balanceTimeStrictness
        case balancedTimes
        case balanceLocationStrictness
        case balancedLocations
        case redistributionSettings
        case flags
    }
}

// MARK: Initialization
extension LeagueGeneralSettings {
    package init(
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
    public func isFlag(_ flag: LeagueSettingFlags) -> Bool {
        flags & UInt32(1 << flag.rawValue) != 0
    }

    /// If we should try arranging matchups so they fit in less time slots than provided.
    public var optimizeTimes: Bool {
        isFlag(.optimizeTimes)
    }

    /// If we should try arranging matchups so they fill earlier time slots first.
    public var prioritizeEarlierTimes: Bool {
        isFlag(.prioritizeEarlierTimes)
    }

    /// If we should try keeping matchups that play at "home" to play at "home" for later matchups (and the same for "away" matchups).
    public var prioritizeHomeAway: Bool {
        isFlag(.prioritizeHomeAway)
    }

    /// If we should try balancing the number each entry plays each other at "home" and "away".
    public var balanceHomeAway: Bool {
        isFlag(.balanceHomeAway)
    }

    /// If we should try keeping teams on the same location if they play back-to-back matchups.
    public var sameLocationIfB2B: Bool {
        isFlag(.sameLocationIfBackToBack)
    }
}