
import OrderedCollections

typealias DayIndex = UInt32
typealias TimeIndex = UInt32
typealias LocationIndex = UInt32
typealias EntryMatchupsPerGameDay = UInt32
typealias EntriesPerMatchup = UInt32
typealias RecurringDayLimitInterval = UInt8

/// Measured in seconds.
typealias MatchupDuration = Double
typealias DayOfWeek = UInt8

// protobufs
typealias AvailableSlot = LitLeagues_Leagues_AvailableSlot
typealias BalanceStrictness = LitLeagues_Leagues_BalanceStrictness
typealias DaySettings = LitLeagues_Leagues_DaySettings
typealias Division = LitLeagues_Leagues_Division
typealias Entry = LitLeagues_Leagues_Entry
typealias GameTimes = LitLeagues_Leagues_GameTimes
typealias GameLocations = LitLeagues_Leagues_GameLocations
typealias GenerationConstraints = LitLeagues_Leagues_GenerationConstraints
typealias GeneralSettings = LitLeagues_Leagues_GeneralSettings
typealias Matchup = LitLeagues_Leagues_Matchup
typealias RequestPayload = LitLeagues_Leagues_RequestPayload
typealias SettingFlags = LitLeagues_Leagues_SettingFlags
typealias LocationTimeExclusivities = LitLeagues_Leagues_LocationTimeExclusivities
typealias LocationTimeExclusivity = LitLeagues_Leagues_LocationTimeExclusivity
typealias LocationTravelDurations = LitLeagues_Leagues_LocationTravelDurations
typealias LocationTravelDurationFrom = LitLeagues_Leagues_LocationTravelDurationFrom
typealias MatchupPair = LitLeagues_Leagues_MatchupPair

/// Number of times an entry was assigned to play at home or away against another entry.
/// 
/// - Usage: [`Entry.IDValue`: [opponent `Entry.IDValue`: [`home (0) or away (1)`: `total played`]]]
typealias AssignedEntryHomeAways = ContiguousArray<ContiguousArray<HomeAwayValue>>

/// Maximum number of times an entry can play against another entry.
///
/// - Usage: [`Entry.IDValue`: [opponent `Entry.IDValue`: `maximum allowed matchups for opponent`]]
typealias MaximumSameOpponentMatchups = ContiguousArray<ContiguousArray<MaximumSameOpponentMatchupsCap>>
typealias MaximumSameOpponentMatchupsCap = UInt32

/// Remaining allocations allowed for a matchup pair, for a `DayIndex`.
/// 
/// - Usage: [`Entry.IDValue`: `the number of remaining allocations`]
typealias RemainingAllocations = ContiguousArray<OrderedSet<AvailableSlot>>

/// When entries can play against each other again.
/// 
/// - Usage: [`Entry.IDValue`: [opponent `Entry.IDValue`: `RecurringDayLimitInterval`]]
typealias RecurringDayLimits = ContiguousArray<ContiguousArray<RecurringDayLimitInterval>>

/// Number of times an entry was assigned to a given time.
/// 
/// - Usage: [`Entry.IDValue`: [`TimeIndex`: `amount played at TimeIndex`]
typealias AssignedTimes = ContiguousArray<ContiguousArray<UInt8>>

/// Number of times an entry was assigned to a given location.
/// 
/// - Usage: [`Entry.IDValue`: [`LocationIndex`: `amount played at LocationIndex`]]
typealias AssignedLocations = ContiguousArray<ContiguousArray<UInt8>>

/// Maximum number of allocations allowed for a given entry for a given time.
/// 
/// - Usage: [`Entry.IDValue`: [`TimeIndex`: `maximum allowed at TimeIndex`]]
typealias MaximumTimeAllocations = ContiguousArray<ContiguousArray<TimeIndex>>

/// Maximum number of allocations allowed for a given entry for a given location.
/// 
/// - Usage: [`Entry.IDValue`: [`LocationIndex`: `maximum allowed at LocationIndex`]]
typealias MaximumLocationAllocations = ContiguousArray<ContiguousArray<LocationIndex>>

/// Times where an entry has already played at for the `day`.
/// 
/// - Usage: [`Entry.IDValue`: `Set<TimeIndex>`]
typealias PlaysAtTimes = ContiguousArray<OrderedSet<TimeIndex>>

/// Locations where an entry has already played at for the `day`.
/// 
/// - Usage: [`Entry.IDValue`: `Set<LocationIndex>`]
typealias PlaysAtLocations = ContiguousArray<Set<LocationIndex>>

/// Slots where an entry has already played at for the `day`.
/// 
/// - Usage: [`Entry.IDValue`: `Set<AvailableSlot>`]
typealias PlaysAt = ContiguousArray<OrderedSet<AvailableSlot>>