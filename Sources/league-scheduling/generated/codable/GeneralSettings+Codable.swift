
#if ProtobufCodable

import StaticDateTimes

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

    enum CodingKeys: CodingKey {
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
#endif