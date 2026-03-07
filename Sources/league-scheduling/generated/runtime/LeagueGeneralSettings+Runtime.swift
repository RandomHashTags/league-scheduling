
import StaticDateTimes

extension LeagueGeneralSettings {
    struct Runtime<Config: ScheduleConfiguration>: Sendable {
        var gameGap:GameGap
        var timeSlots:LeagueTimeIndex
        var startingTimes:[StaticTime]
        var entriesPerLocation:LeagueEntriesPerMatchup
        var locations:LeagueLocationIndex
        var defaultMaxEntryMatchupsPerGameDay:LeagueEntryMatchupsPerGameDay
        var maximumPlayableMatchups:[UInt32]
        var matchupDuration:LeagueMatchupDuration
        var locationTimeExclusivities:[Config.TimeSet]?
        var locationTravelDurations:[[LeagueMatchupDuration]]?
        var balanceTimeStrictness:LeagueBalanceStrictness
        var balancedTimes:Config.TimeSet
        var balanceLocationStrictness:LeagueBalanceStrictness
        var balancedLocations:Config.LocationSet
        var redistributionSettings:LitLeagues_Leagues_RedistributionSettings?
        var flags:UInt32
    }
}

extension LeagueGeneralSettings.Runtime {
    init(
        gameGap: GameGap,
        protobuf: LeagueGeneralSettings
    ) {
        self.gameGap = gameGap
        timeSlots = protobuf.timeSlots
        startingTimes = protobuf.startingTimes.times
        entriesPerLocation = protobuf.entriesPerLocation
        locations = protobuf.locations
        defaultMaxEntryMatchupsPerGameDay = protobuf.entryMatchupsPerGameDay
        maximumPlayableMatchups = protobuf.maximumPlayableMatchups.array
        matchupDuration = protobuf.matchupDuration
        if protobuf.hasLocationTimeExclusivities {
            locationTimeExclusivities = protobuf.locationTimeExclusivities.locations.map({ .init($0.times) })
        } else {
            locationTimeExclusivities = nil
        }
        if protobuf.hasLocationTravelDurations {
            locationTravelDurations = protobuf.locationTravelDurations.locations.map({ $0.travelDurationTo })
        } else {
            locationTravelDurations = nil
        }
        balanceTimeStrictness = protobuf.balanceTimeStrictness
        balancedTimes = .init(protobuf.balancedTimes.array)
        balanceLocationStrictness = protobuf.balanceLocationStrictness
        balancedLocations = .init(protobuf.balancedLocations.array)
        if protobuf.hasRedistributionSettings {
            redistributionSettings = protobuf.redistributionSettings
        } else {
            redistributionSettings = nil
        }
        flags = protobuf.flags
    }

    mutating func apply(
        gameDays: LeagueDayIndex,
        entriesCount: Int,
        correctMaximumPlayableMatchups: [UInt32],
        general: Self,
        customDaySettings: LeagueGeneralSettings
    ) {
        if customDaySettings.hasGameGap, let gg = GameGap(htmlInputValue: customDaySettings.gameGap) {
            self.gameGap = gg
        }
        if customDaySettings.hasTimeSlots {
            self.timeSlots = customDaySettings.timeSlots
        }
        if customDaySettings.hasStartingTimes {
            self.startingTimes = customDaySettings.startingTimes.times
        }
        if customDaySettings.hasEntriesPerLocation {
            self.entriesPerLocation = customDaySettings.entriesPerLocation
        }
        if customDaySettings.hasLocations {
            self.locations = customDaySettings.locations
        }
        if customDaySettings.hasEntryMatchupsPerGameDay {
            self.defaultMaxEntryMatchupsPerGameDay = customDaySettings.entryMatchupsPerGameDay
        }
        if customDaySettings.hasMaximumPlayableMatchups {
            self.maximumPlayableMatchups = LeagueRequestPayload.calculateMaximumPlayableMatchups(
                gameDays: gameDays,
                entryMatchupsPerGameDay: self.defaultMaxEntryMatchupsPerGameDay,
                teamsCount: entriesCount,
                maximumPlayableMatchups: customDaySettings.maximumPlayableMatchups.array
            )
        } else {
            self.maximumPlayableMatchups = correctMaximumPlayableMatchups
        }
        if customDaySettings.hasMatchupDuration {
            self.matchupDuration = customDaySettings.matchupDuration
        }
        if customDaySettings.hasLocationTimeExclusivities {
            self.locationTimeExclusivities = customDaySettings.locationTimeExclusivities.locations.map({ Config.TimeSet($0.times) })
        }
        if customDaySettings.hasLocationTravelDurations {
            self.locationTravelDurations = customDaySettings.locationTravelDurations.locations.map({ $0.travelDurationTo })
        }
        if customDaySettings.hasBalanceTimeStrictness {
            self.balanceTimeStrictness = customDaySettings.balanceTimeStrictness
        }
        if customDaySettings.hasBalanceLocationStrictness {
            self.balanceLocationStrictness = customDaySettings.balanceLocationStrictness
        }
        if customDaySettings.hasRedistributionSettings {
            self.redistributionSettings = customDaySettings.redistributionSettings
            if let defaultSettings = general.redistributionSettings {
                if !customDaySettings.redistributionSettings.hasMinMatchupsRequired, defaultSettings.hasMinMatchupsRequired {
                    self.redistributionSettings!.minMatchupsRequired = defaultSettings.minMatchupsRequired
                }
                if !customDaySettings.redistributionSettings.hasMaxMovableMatchups, defaultSettings.hasMaxMovableMatchups {
                    self.redistributionSettings!.maxMovableMatchups = defaultSettings.maxMovableMatchups
                }
            }
        }
        if customDaySettings.hasFlags {
            self.flags = customDaySettings.flags
        }
    }

    func availableSlots() -> Set<LeagueAvailableSlot> {
        var slots = Set<LeagueAvailableSlot>(minimumCapacity: timeSlots * locations)
        if let exclusivities = locationTimeExclusivities {
            for location in 0..<locations {
                if let timeExclusives = exclusivities[uncheckedPositive: location] {
                    for time in 0..<timeSlots {
                        if timeExclusives.contains(time) {
                            let slot = LeagueAvailableSlot(time: time, location: location)
                            slots.insert(slot)
                        }
                    }
                }
            }
        } else {
            for time in 0..<timeSlots {
                for location in 0..<locations {
                    let slot = LeagueAvailableSlot(time: time, location: location)
                    slots.insert(slot)
                }
            }
        }
        return slots
    }

    func containsBalancedTime(_ timeSlot: LeagueTimeIndex) -> Bool {
        balancedTimes.contains(timeSlot)
    }
    func containsBalancedLocation(_ location: LeagueLocationIndex) -> Bool {
        balancedLocations.contains(location)
    }

    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>>)
    @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>)
    init(
        gameGap: GameGap,
        timeSlots: LeagueTimeIndex,
        startingTimes: [StaticTime],
        entriesPerLocation: LeagueEntriesPerMatchup,
        locations: LeagueLocationIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32],
        matchupDuration: LeagueMatchupDuration,
        locationTimeExclusivities: [Config.TimeSet]?,
        locationTravelDurations: [[LeagueMatchupDuration]]?,
        balanceTimeStrictness: LeagueBalanceStrictness,
        balancedTimes: Config.TimeSet,
        balanceLocationStrictness: LeagueBalanceStrictness,
        balancedLocations: Config.LocationSet,
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