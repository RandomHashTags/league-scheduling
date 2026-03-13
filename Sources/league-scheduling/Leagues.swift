
import SwiftProtobuf

// MARK: typealiases
public typealias LeagueDayIndex = UInt32                 // WARNING: do not change value type!
public typealias LeagueTimeIndex = UInt32                // WARNING: do not change value type!
public typealias LeagueLocationIndex = UInt32            // WARNING: do not change value type!
public typealias LeagueEntryMatchupsPerGameDay = UInt32  // WARNING: do not change value type!
public typealias LeagueEntriesPerMatchup = UInt32        // WARNING: do not change value type!
public typealias LeagueRegenerationAttempt = UInt16      // WARNING: do not change value type!
public typealias LeagueRecurringDayLimitInterval = UInt8 // WARNING: do not change value type!

/// Measured in seconds.
public typealias LeagueMatchupDuration = Double          // WARNING: do not change value type!
public typealias LeagueDayOfWeek = UInt8                 // WARNING: do not change value type!


// protobufs
public typealias LeagueAvailableSlot = LitLeagues_Leagues_AvailableSlot
public typealias LeagueBalanceStrictness = LitLeagues_Leagues_BalanceStrictness
public typealias LeagueDaySettings = LitLeagues_Leagues_DaySettings
public typealias LeagueDivision = LitLeagues_Leagues_Division
public typealias LeagueEntry = LitLeagues_Leagues_Entry
public typealias LeagueGameTimes = LitLeagues_Leagues_GameTimes
public typealias LeagueGameLocations = LitLeagues_Leagues_GameLocations
//public typealias LeagueEntryMatchupsPerGameDay = LitLeagues_Leagues_EntryMatchupsPerGameDay
public typealias LeagueGeneralSettings = LitLeagues_Leagues_GeneralSettings
public typealias LeagueMatchup = LitLeagues_Leagues_Matchup
public typealias LeagueRequestPayload = LitLeagues_Leagues_RequestPayload
public typealias LeagueSettingFlags = LitLeagues_Leagues_SettingFlags
public typealias LeagueLocationTimeExclusivities = LitLeagues_Leagues_LocationTimeExclusivities
public typealias LeagueLocationTimeExclusivity = LitLeagues_Leagues_LocationTimeExclusivity
public typealias LeagueLocationTravelDurations = LitLeagues_Leagues_LocationTravelDurations
public typealias LeagueLocationTravelDurationFrom = LitLeagues_Leagues_LocationTravelDurationFrom
public typealias LeagueMatchupPair = LitLeagues_Leagues_MatchupPair


/// Number of times an entry was assigned to play at home or away against another entry.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: [`home (0) or away (1)`: `total played`]]]
typealias AssignedEntryHomeAways = ContiguousArray<ContiguousArray<HomeAwayValue>>

/// Maximum number of times an entry can play against another entry.
///
/// - Usage: [`LeagueEntry.IDValue`: [opponent `LeagueEntry.IDValue`: `maximum allowed matchups for opponent`]]
public typealias LeagueMaximumSameOpponentMatchups = ContiguousArray<ContiguousArray<LeagueMaximumSameOpponentMatchupsCap>>
public typealias LeagueMaximumSameOpponentMatchupsCap = UInt32

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
public typealias LeagueAssignedTimes = ContiguousArray<ContiguousArray<UInt8>>

/// Number of times an entry was assigned to a given location.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `amount played at LeagueLocationIndex`]]
public typealias LeagueAssignedLocations = ContiguousArray<ContiguousArray<UInt8>>

/// Maximum number of allocations allowed for a given entry for a given time.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueTimeIndex`: `maximum allowed at LeagueTimeIndex`]]
typealias MaximumTimeAllocations = ContiguousArray<ContiguousArray<LeagueTimeIndex>>

/// Maximum number of allocations allowed for a given entry for a given location.
/// 
/// - Usage: [`LeagueEntry.IDValue`: [`LeagueLocationIndex`: `maximum allowed at LeagueLocationIndex`]]
typealias MaximumLocationAllocations = ContiguousArray<ContiguousArray<LeagueLocationIndex>>

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

    public static let maximumAllowedRegenerationAttemptsForANegativeDayIndex:LeagueRegenerationAttempt = 100
    public static let maximumAllowedRegenerationAttemptsForASingleDay:LeagueRegenerationAttempt = 100
    public static let failedRegenerationAttemptsThreshold:LeagueRegenerationAttempt = 10_000
}

// MARK: global
func optimalTimeSlots(
    availableTimeSlots: LeagueTimeIndex,
    locations: LeagueLocationIndex,
    matchupsCount: LeagueLocationIndex
) -> LeagueTimeIndex {
    var totalMatchupsPlayed:LeagueLocationIndex = 0
    var filledTimes:LeagueTimeIndex = 0
    while totalMatchupsPlayed < matchupsCount {
        filledTimes += 1
        totalMatchupsPlayed += locations
    }
    #if LOG
    print("LeagueSchedule;optimalTimeSlots;availableTimeSlots=\(availableTimeSlots);locations=\(locations);matchupsCount=\(matchupsCount);totalMatchupsPlayed=\(totalMatchupsPlayed);filledTimes=\(filledTimes)")
    #endif
    return min(availableTimeSlots, filledTimes)
}

func calculateAdjacentTimes<TimeSet: SetOfTimeIndexes>(
    for time: LeagueTimeIndex,
    entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay
) -> TimeSet {
    var adjacentTimes = TimeSet()
    let timeIndex = time % entryMatchupsPerGameDay
    if timeIndex == 0 {
        for i in 1..<LeagueTimeIndex(entryMatchupsPerGameDay) {
            adjacentTimes.insertMember(time + i)
        }
    } else {
        for i in 1..<timeIndex+1 {
            adjacentTimes.insertMember(time - i)
        }
        if timeIndex < entryMatchupsPerGameDay-1 {
            for i in 1..<entryMatchupsPerGameDay - timeIndex {
                adjacentTimes.insertMember(time + i)
            }
        }
    }
    return adjacentTimes
}