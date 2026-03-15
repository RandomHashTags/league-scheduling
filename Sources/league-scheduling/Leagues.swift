
import SwiftProtobuf

// MARK: typealiases
typealias LeagueDayIndex = UInt32                  // WARNING: do not change value type!
typealias LeagueTimeIndex = UInt32                 // WARNING: do not change value type!
typealias LeagueLocationIndex = UInt32             // WARNING: do not change value type!
typealias LeagueEntryMatchupsPerGameDay = UInt32   // WARNING: do not change value type!
typealias LeagueEntriesPerMatchup = UInt32         // WARNING: do not change value type!
typealias LeagueRecurringDayLimitInterval = UInt8  // WARNING: do not change value type!

/// Measured in seconds.
typealias LeagueMatchupDuration = Double            // WARNING: do not change value type!
typealias LeagueDayOfWeek = UInt8                   // WARNING: do not change value type!


// protobufs
typealias LeagueAvailableSlot = LitLeagues_Leagues_AvailableSlot
typealias LeagueBalanceStrictness = LitLeagues_Leagues_BalanceStrictness
typealias LeagueDaySettings = LitLeagues_Leagues_DaySettings
typealias LeagueDivision = LitLeagues_Leagues_Division
typealias LeagueEntry = LitLeagues_Leagues_Entry
typealias LeagueGameTimes = LitLeagues_Leagues_GameTimes
typealias LeagueGameLocations = LitLeagues_Leagues_GameLocations
typealias GenerationConstraints = LitLeagues_Leagues_GenerationConstraints
typealias LeagueGeneralSettings = LitLeagues_Leagues_GeneralSettings
typealias LeagueMatchup = LitLeagues_Leagues_Matchup
typealias LeagueRequestPayload = LitLeagues_Leagues_RequestPayload
typealias LeagueSettingFlags = LitLeagues_Leagues_SettingFlags
typealias LeagueLocationTimeExclusivities = LitLeagues_Leagues_LocationTimeExclusivities
typealias LeagueLocationTimeExclusivity = LitLeagues_Leagues_LocationTimeExclusivity
typealias LeagueLocationTravelDurations = LitLeagues_Leagues_LocationTravelDurations
typealias LeagueLocationTravelDurationFrom = LitLeagues_Leagues_LocationTravelDurationFrom
typealias LeagueMatchupPair = LitLeagues_Leagues_MatchupPair

/// Number of times an entry was assigned to play at home or away against another entry.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: [`home (0) or away (1)`: `total played`]]]
typealias AssignedEntryHomeAways = ContiguousArray<ContiguousArray<LeagueSchedule.HomeAwayValue>>

/// Maximum number of times an entry can play against another entry.
///
/// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: `maximum allowed matchups for opponent`]]
typealias LeagueMaximumSameOpponentMatchups = ContiguousArray<ContiguousArray<LeagueMaximumSameOpponentMatchupsCap>>
typealias LeagueMaximumSameOpponentMatchupsCap = UInt32

/// Remaining allocations allowed for a matchup pair, for a `LeagueDayIndex`.
/// 
/// - Usage: [`LeagueEntry.IDValue`: `the number of remaining allocations`]
typealias RemainingAllocations = ContiguousArray<Set<LeagueAvailableSlot>>

/// When entries can play against each other again.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: `LeagueRecurringDayLimitInterval`]]
typealias RecurringDayLimits = ContiguousArray<ContiguousArray<LeagueRecurringDayLimitInterval>>

/// Number of times an entry was assigned to a given time.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueTimeIndex`: `amount played at LeagueTimeIndex`]
typealias LeagueAssignedTimes = ContiguousArray<ContiguousArray<UInt8>>

/// Number of times an entry was assigned to a given location.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `amount played at LeagueLocationIndex`]]
typealias LeagueAssignedLocations = ContiguousArray<ContiguousArray<UInt8>>

/// Maximum number of allocations allowed for a given entry for a given time.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueTimeIndex`: `maximum allowed at LeagueTimeIndex`]]
typealias MaximumTimeAllocations = ContiguousArray<ContiguousArray<LeagueTimeIndex>>

/// Maximum number of allocations allowed for a given entry for a given location.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `maximum allowed at LeagueLocationIndex`]]
typealias MaximumLocationAllocations = ContiguousArray<ContiguousArray<LeagueLocationIndex>>

/// Times where an entry has already played at for the `day`.
/// 
/// - Usage: [`LeagueEntry.IDValue`: `Set<LeagueTimeIndex>`]
typealias PlaysAtTimes = ContiguousArray<Set<LeagueTimeIndex>>

/// Locations where an entry has already played at for the `day`.
/// 
/// - Usage: [`LeagueEntry.IDValue`: `Set<LeagueLocationIndex>`]
typealias PlaysAtLocations = ContiguousArray<Set<LeagueLocationIndex>>

/// Slots where an entry has already played at for the `day`.
/// 
/// - Usage: [`LeagueEntry.IDValue`: `Set<LeagueAvailableSlot>`]
typealias PlaysAt = ContiguousArray<Set<LeagueAvailableSlot>>

// MARK: Leagues3
public struct Leagues3 {
    public static let protobufJSONEncodingOptions: JSONEncodingOptions = {
        var options = JSONEncodingOptions()
        options.alwaysPrintEnumsAsInts = true
        options.alwaysPrintInt64sAsNumbers = true
        return options
    }()
}