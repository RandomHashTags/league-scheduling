
import StaticDateTimes

extension GeneralSettings {
    struct Runtime<Config: ScheduleConfiguration>: Sendable {
        var gameGap:GameGap
        var timeSlots:TimeIndex
        var startingTimes:[StaticTime]
        var entriesPerLocation:EntriesPerMatchup
        var locations:LocationIndex
        var defaultMaxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay
        var maximumPlayableMatchups:[UInt32]
        var matchupDuration:MatchupDuration
        var locationTimeExclusivities:[Config.TimeSet]?
        var locationTravelDurations:[[MatchupDuration]]?
        var balanceTimeStrictness:BalanceStrictness
        var balancedTimes:Config.TimeSet
        var balanceLocationStrictness:BalanceStrictness
        var balancedLocations:Config.LocationSet
        var redistributionSettings:LitLeagues_Leagues_RedistributionSettings?
        var flags:UInt32
    }
}

// MARK: Init
extension GeneralSettings.Runtime {
    init(
        gameGap: GameGap,
        protobuf: GeneralSettings
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

    #if SpecializeScheduleConfiguration
    @_specialize(where Config == ScheduleConfig<BitSet64<DayIndex>, BitSet64<TimeIndex>, BitSet64<LocationIndex>, BitSet64<Entry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<Set<DayIndex>, Set<TimeIndex>, Set<LocationIndex>, Set<Entry.IDValue>>)
    #endif
    init(
        gameGap: GameGap,
        timeSlots: TimeIndex,
        startingTimes: [StaticTime],
        entriesPerLocation: EntriesPerMatchup,
        locations: LocationIndex,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32],
        matchupDuration: MatchupDuration,
        locationTimeExclusivities: [Config.TimeSet]?,
        locationTravelDurations: [[MatchupDuration]]?,
        balanceTimeStrictness: BalanceStrictness,
        balancedTimes: Config.TimeSet,
        balanceLocationStrictness: BalanceStrictness,
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

// MARK: Available slots
extension GeneralSettings.Runtime {
    func availableSlots() -> Set<AvailableSlot> {
        var slots = Set<AvailableSlot>(minimumCapacity: timeSlots * locations)
        if let exclusivities = locationTimeExclusivities {
            for location in 0..<locations {
                if let timeExclusives = exclusivities[uncheckedPositive: location] {
                    for time in 0..<timeSlots {
                        if timeExclusives.contains(time) {
                            let slot = AvailableSlot(time: time, location: location)
                            slots.insert(slot)
                        }
                    }
                }
            }
        } else {
            for time in 0..<timeSlots {
                for location in 0..<locations {
                    let slot = AvailableSlot(time: time, location: location)
                    slots.insert(slot)
                }
            }
        }
        return slots
    }
}

// MARK: Apply
extension GeneralSettings.Runtime {
    mutating func apply(
        gameDays: DayIndex,
        entriesCount: Int,
        correctMaximumPlayableMatchups: [UInt32],
        general: Self,
        customDaySettings: GeneralSettings
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
            self.maximumPlayableMatchups = RequestPayload.calculateMaximumPlayableMatchups(
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
}

// MARK: Flags
extension GeneralSettings.Runtime {
    func isFlag(_ flag: SettingFlags) -> Bool {
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

// MARK: Compute settings
extension GeneralSettings.Runtime {
    init(
        protobuf: GeneralSettings
    ) throws(LeagueError) {
        guard let gameGap = GameGap(htmlInputValue: protobuf.gameGap) else {
            throw .malformedInput(msg: "invalid GameGap htmlInputValue: \(protobuf.gameGap)")
        }
        self.init(gameGap: gameGap, protobuf: protobuf)
    }

    /// Modifies `timeSlots` and `startingTimes` taking into account current settings.
    mutating func computeSettings(
        day: DayIndex,
        entries: [Config.EntryRuntime]
    ) {
        if optimizeTimes {
            var maxMatchupsPlayedToday:LocationIndex = 0
            for entry in entries {
                if entry.gameDays.contains(day) && !entry.byes.contains(day) {
                    maxMatchupsPlayedToday += entry.maxMatchupsForGameDay(day: day, fallback: defaultMaxEntryMatchupsPerGameDay)
                }
            }
            maxMatchupsPlayedToday /= entriesPerLocation
            let filledTimeSlots = optimalTimeSlots(
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