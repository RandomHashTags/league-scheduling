
import struct FoundationEssentials.Date
import StaticDateTimes

#if canImport(SwiftGlibc)
import SwiftGlibc
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Parse
extension LeagueRequestPayload {
    func parseSettings() throws(LeagueError) -> LeagueRequestPayload.Runtime {
        guard gameDays > 0 else {
            throw .malformedInput(msg: "'gameDays' needs to be > 0")
        }
        let divisionsCount:Int
        if hasDivisions {
            guard divisions.divisions.count > 0 else {
                throw .malformedInput(msg: "'divisions' needs to be > 0")
            }
            divisionsCount = divisions.divisions.count
        } else {
            divisionsCount = 1
        }
        guard entries.count > 0 else {
            throw .malformedInput(msg: "'entries' needs to be > 0")
        }
        if hasIndividualDaySettings {
            guard individualDaySettings.days.count == gameDays else {
                throw .malformedInput(msg: "'individualDaySettings' size != \(gameDays)")
            }
        }
        guard let defaultGameGap = try validateSettings(kind: "default", settings: settings, fallbackSettings: settings) else {
            throw .malformedInput(msg: "missing default 'gameGap' value")
        }
        if hasIndividualDaySettings {
            for (dayIndex, daySettings) in individualDaySettings.days.enumerated() {
                if daySettings.hasSettings {
                    try validateSettings(kind: "for day \(dayIndex), individual day setting", settings: daySettings.settings, fallbackSettings: settings)
                }
            }
        }
        let startingDayOfWeek:LeagueDayOfWeek
        if hasStarts {
            guard let starts = StaticDate(htmlDate: starts) else {
                throw .malformedHTMLDateInput(key: "starts", value: starts)
            }
            startingDayOfWeek = starts.dayOfWeek
        } else if hasDivisions, let dow = divisions.divisions.first(where: { $0.hasDayOfWeek })?.dayOfWeek, dow <= UInt8.max {
            startingDayOfWeek = UInt8(dow)
        } else {
            startingDayOfWeek = 0
        }
        var teamsForDivision = [Int](repeating: 0, count: divisionsCount)
        let divisionDefaults = loadDivisionDefaults(divisionsCount: divisionsCount)
        let entries = try parseEntries(
            divisionsCount: divisionsCount,
            teams: entries,
            teamsForDivision: &teamsForDivision,
            divisionDefaults: divisionDefaults
        )
        let runtimeDivisions = try parseDivisions(
            divisionsCount: divisionsCount,
            locations: settings.locations,
            divisionGameDays: divisionDefaults.gameDays,
            defaultGameGap: defaultGameGap,
            fallbackDayOfWeek: startingDayOfWeek,
            teamsForDivision: teamsForDivision
        )
        let timesSet = BitSet64<LeagueTimeIndex>(0..<settings.timeSlots)
        let locationsSet = BitSet64<LeagueLocationIndex>(0..<settings.locations)
        var defaultTimeExclusivities = Array(repeating: timesSet, count: settings.locations)
        if settings.hasLocationTimeExclusivities {
            for (location, exclusivities) in settings.locationTimeExclusivities.locations.enumerated() {
                if !exclusivities.times.isEmpty {
                    defaultTimeExclusivities[unchecked: location] = BitSet64(exclusivities.times)
                }
            }
        }
        var defaultTravelDurations:[[LeagueMatchupDuration]] = .init(repeating: .init(repeating: 0, count: settings.locations), count: settings.locations)
        if settings.hasLocationTravelDurations {
            for (fromLocation, values) in settings.locationTravelDurations.locations.enumerated() {
                if !values.travelDurationTo.isEmpty {
                    defaultTravelDurations[fromLocation] = values.travelDurationTo
                }
            }
        }
        var balancedTimes:BitSet64<LeagueTimeIndex>
        var balancedLocations:BitSet64<LeagueLocationIndex>
        if settings.balanceTimeStrictness != .lenient {
            balancedTimes = timesSet
        } else {
            balancedTimes = .init()
        }
        if settings.balanceLocationStrictness != .lenient {
            balancedLocations = locationsSet
        } else {
            balancedLocations = .init()
        }

        let correctMaximumPlayableMatchups = Self.calculateMaximumPlayableMatchups(
            gameDays: gameDays,
            entryMatchupsPerGameDay: settings.entryMatchupsPerGameDay,
            teamsCount: entries.count,
            maximumPlayableMatchups: settings.maximumPlayableMatchups.array
        )
        let general = LeagueGeneralSettings.Runtime(
            gameGap: defaultGameGap,
            timeSlots: settings.timeSlots,
            startingTimes: settings.startingTimes.times,
            entriesPerLocation: settings.entriesPerLocation,
            locations: settings.locations,
            entryMatchupsPerGameDay: settings.entryMatchupsPerGameDay,
            maximumPlayableMatchups: correctMaximumPlayableMatchups,
            matchupDuration: settings.matchupDuration,
            locationTimeExclusivities: defaultTimeExclusivities,
            locationTravelDurations: defaultTravelDurations,
            balanceTimeStrictness: settings.balanceTimeStrictness,
            balancedTimes: balancedTimes,
            balanceLocationStrictness: settings.balanceLocationStrictness,
            balancedLocations: balancedLocations,
            redistributionSettings: settings.hasRedistributionSettings ? settings.redistributionSettings : nil,
            flags: settings.flags
        )
        let daySettings = try parseDaySettings(
            general: general,
            correctMaximumPlayableMatchups: correctMaximumPlayableMatchups,
            entries: entries
        )
        return .init(
            gameDays: gameDays,
            divisions: runtimeDivisions,
            entries: entries,
            general: general,
            daySettings: daySettings
        )
    }
}

// MARK: Division defaults
extension LeagueRequestPayload {
    struct DivisionDefaults: Sendable, ~Copyable {
        let gameDays:[Set<LeagueDayIndex>]
        let byes:[Set<LeagueDayIndex>]
        let gameTimes:[[BitSet64<LeagueTimeIndex>]]
        let gameLocations:[[BitSet64<LeagueLocationIndex>]]
    }
}

// MARK: Load division defaults
extension LeagueRequestPayload {
    private func loadDivisionDefaults(
        divisionsCount: Int
    ) -> DivisionDefaults {
        var gameDays = [Set<LeagueDayIndex>]()
        var byes = [Set<LeagueDayIndex>]()
        var gameTimes = [[BitSet64<LeagueTimeIndex>]]()
        var gameLocations = [[BitSet64<LeagueLocationIndex>]]()
        gameDays.reserveCapacity(divisionsCount)
        byes.reserveCapacity(divisionsCount)
        gameTimes.reserveCapacity(divisionsCount)
        gameLocations.reserveCapacity(divisionsCount)

        let getTimesFunc:@Sendable (LeagueRequestPayload, LeagueDayIndex, LeagueTimeIndex) -> LeagueTimeIndex
        let getLocationsFunc:@Sendable (LeagueRequestPayload, LeagueDayIndex, LeagueLocationIndex) -> LeagueLocationIndex
        if hasIndividualDaySettings {
            getTimesFunc = Self.individualDayTimes
            getLocationsFunc = Self.individualDayLocations
        } else {
            getTimesFunc = { _, _, fallback in return fallback }
            getLocationsFunc = { _, _, fallback in return fallback }
        }
        if hasDivisions {
            for division in divisions.divisions {
                let targetGameDays:Set<LeagueDayIndex>
                if division.hasGameDays {
                    targetGameDays = Set(division.gameDays.gameDayIndexes)
                } else {
                    targetGameDays = Set(0..<self.gameDays)
                }
                gameDays.append(targetGameDays)
                if division.hasByes {
                    byes.append(Set(division.byes.byes))
                } else {
                    byes.append([])
                }
                if division.hasGameDayTimes {
                    gameTimes.append(division.gameDayTimes.times.map({ .init($0.times) }))
                } else {
                    var dgdt = [BitSet64<LeagueTimeIndex>]()
                    for gameDay in 0..<self.gameDays {
                        let times = getTimesFunc(self, gameDay, settings.timeSlots)
                        dgdt.append(.init(0..<times))
                    }
                    gameTimes.append(dgdt)
                }
                if division.hasGameDayLocations {
                    gameLocations.append(division.gameDayLocations.locations.map({ .init($0.locations) }))
                } else {
                    var dgdl = [BitSet64<LeagueLocationIndex>]()
                    for gameDay in 0..<self.gameDays {
                        let locations = getLocationsFunc(self, gameDay, settings.locations)
                        dgdl.append(.init(0..<locations))
                    }
                    gameLocations.append(dgdl)
                }
            }
        } else {
            gameDays.append(Set(0..<self.gameDays))
            byes.append([])

            var dgdt = [BitSet64<LeagueTimeIndex>]()
            for gameDay in 0..<self.gameDays {
                let times = getTimesFunc(self, gameDay, settings.timeSlots)
                dgdt.append(.init(0..<times))
            }
            gameTimes.append(dgdt)

            var dgdl = [BitSet64<LeagueLocationIndex>]()
            for gameDay in 0..<self.gameDays {
                let locations = getLocationsFunc(self, gameDay, settings.locations)
                dgdl.append(.init(0..<locations))
            }
            gameLocations.append(dgdl)
        }
        return .init(
            gameDays: gameDays,
            byes: byes,
            gameTimes: gameTimes,
            gameLocations: gameLocations
        )
    }
    private static func individualDayTimes(
        payload: LeagueRequestPayload,
        dayIndex: LeagueDayIndex,
        fallback: LeagueTimeIndex
    ) -> LeagueTimeIndex {
        let daySettings = payload.individualDaySettings.days[unchecked: dayIndex]
        guard daySettings.hasSettings, daySettings.settings.hasTimeSlots else { return fallback }
        return daySettings.settings.timeSlots
    }
    private static func individualDayLocations(
        payload: LeagueRequestPayload,
        dayIndex: LeagueDayIndex,
        fallback: LeagueLocationIndex
    ) -> LeagueLocationIndex {
        let daySettings = payload.individualDaySettings.days[unchecked: dayIndex]
        guard daySettings.hasSettings, daySettings.settings.hasLocations else { return fallback }
        return LeagueTimeIndex(daySettings.settings.locations)
    }
}

// MARK: Parse teams
extension LeagueRequestPayload {
    private func parseEntries(
        divisionsCount: Int,
        teams: [LeagueEntry],
        teamsForDivision: inout [Int],
        divisionDefaults: borrowing DivisionDefaults
    ) throws(LeagueError) -> [LeagueEntry.Runtime] {
        var entries = [LeagueEntry.Runtime]()
        entries.reserveCapacity(teams.count)
        for (i, team) in teams.enumerated() {
            if team.hasGameDayTimes {
                guard team.gameDayTimes.times.count == gameDays else {
                    throw .malformedInput(msg: "'gameTimes' size != \(gameDays) for team at index \(i)")
                }
            }
            if team.hasGameDayLocations {
                guard team.gameDayLocations.locations.count == gameDays else {
                    throw .malformedInput(msg: "'gameLocations' size != \(gameDays) for team at index \(i)")
                }
            }
            if team.hasMatchupsPerGameDay {
                guard team.matchupsPerGameDay.gameDayMatchups.count == gameDays else {
                    throw .malformedInput(msg: "'matchupsPerGameDay.gameDayMatchups' size != \(gameDays) for team at index \(i)")
                }
            }
            let division = min(team.division, UInt32(divisionsCount - 1))
            teamsForDivision[Int(division)] += 1
            entries.append(team.runtime(
                id: LeagueEntry.IDValue(i),
                division: division,
                defaultGameDays: divisionDefaults.gameDays[unchecked: division],
                defaultByes: divisionDefaults.byes[unchecked: division],
                defaultGameTimes: divisionDefaults.gameTimes[unchecked: division],
                defaultGameLocations: divisionDefaults.gameLocations[unchecked: division]
            ))
        }
        return entries
    }
}

// MARK: Parse divisions
extension LeagueRequestPayload {
    private func parseDivisions(
        divisionsCount: Int,
        locations: LeagueLocationIndex,
        divisionGameDays: [Set<LeagueDayIndex>],
        defaultGameGap: GameGap,
        fallbackDayOfWeek: LeagueDayOfWeek,
        teamsForDivision: [Int]
    ) throws(LeagueError) -> [LeagueDivision.Runtime] {
        var runtimeDivisions = [LeagueDivision.Runtime]()
        runtimeDivisions.reserveCapacity(divisionsCount)
        if hasDivisions {
            for (i, division) in divisions.divisions.enumerated() {
                if division.hasOpponents {
                    guard division.opponents.divisionOpponentIds.count > 0 else {
                        throw .malformedInput(msg: "'opponents' size needs to be > 0 for division at index \(i)")
                    }
                }
                if division.hasGameDayTimes {
                    guard division.gameDayTimes.times.count == gameDays else {
                        throw .malformedInput(msg: "'gameDayTimes' size != \(gameDays) for division at index \(i)")
                    }
                }
                if division.hasGameDayLocations {
                    guard division.gameDayLocations.locations.count == gameDays else {
                        throw .malformedInput(msg: "'gameDayLocations' size != \(gameDays) for division at index \(i)")
                    }
                }
                if division.hasTravelDurations {
                    guard division.travelDurations.locations.count == locations else {
                        throw .malformedInput(msg: "'travelDurations' size != \(locations) for division at index \(i)")
                    }
                }
                if division.hasLocationTimeExclusivities {
                    guard division.locationTimeExclusivities.locations.count == locations else {
                        throw .malformedInput(msg: "'locationTimeExclusivities' size != \(locations) for division at index \(i)")
                    }
                }
                let maxSameOpponentMatchups = try calculateMaximumSameOpponentMatchupsCap(entriesCount: teamsForDivision[Int(i)])
                try runtimeDivisions.append(division.runtime(
                    defaultGameDays: divisionGameDays[unchecked: i],
                    defaultGameGap: defaultGameGap,
                    fallbackDayOfWeek: fallbackDayOfWeek,
                    fallbackMaxSameOpponentMatchups: maxSameOpponentMatchups
                ))
            }
        } else {
            let maxSameOpponentMatchups = try calculateMaximumSameOpponentMatchupsCap(entriesCount: teamsForDivision[0])
            runtimeDivisions.append(.init(
                dayOfWeek: fallbackDayOfWeek,
                gameDays: divisionGameDays[unchecked: 0],
                gameGaps: .init(repeating: defaultGameGap, count: gameDays),
                maxSameOpponentMatchups: maxSameOpponentMatchups
            ))
        }
        return runtimeDivisions
    }
}

// MARK: Parse day settings
extension LeagueRequestPayload {
    private func parseDaySettings(
        general: LeagueGeneralSettings.Runtime,
        correctMaximumPlayableMatchups: [UInt32],
        entries: [LeagueEntry.Runtime]
    ) throws(LeagueError) -> [LeagueDaySettings.Runtime] {
        var daySettings = [LeagueDaySettings.Runtime]()
        daySettings.reserveCapacity(gameDays)
        if hasIndividualDaySettings {
            for dayIndex in 0..<gameDays {
                var settings = general
                let targetDaySettings = individualDaySettings.days[unchecked: dayIndex]
                if targetDaySettings.hasSettings {
                    let customDaySettings = targetDaySettings.settings
                    if customDaySettings.hasGameGap, let gg = GameGap(htmlInputValue: customDaySettings.gameGap) {
                        settings.gameGap = gg
                    }
                    if customDaySettings.hasTimeSlots {
                        settings.timeSlots = customDaySettings.timeSlots
                    }
                    if customDaySettings.hasStartingTimes {
                        settings.startingTimes = customDaySettings.startingTimes.times
                    }
                    if customDaySettings.hasEntriesPerLocation {
                        settings.entriesPerLocation = customDaySettings.entriesPerLocation
                    }
                    if customDaySettings.hasLocations {
                        settings.locations = customDaySettings.locations
                    }
                    if customDaySettings.hasEntryMatchupsPerGameDay {
                        settings.defaultMaxEntryMatchupsPerGameDay = customDaySettings.entryMatchupsPerGameDay
                    }
                    if customDaySettings.hasMaximumPlayableMatchups {
                        settings.maximumPlayableMatchups = Self.calculateMaximumPlayableMatchups(
                            gameDays: gameDays,
                            entryMatchupsPerGameDay: settings.defaultMaxEntryMatchupsPerGameDay,
                            teamsCount: entries.count,
                            maximumPlayableMatchups: customDaySettings.maximumPlayableMatchups.array
                        )
                    } else {
                        settings.maximumPlayableMatchups = correctMaximumPlayableMatchups
                    }
                    if customDaySettings.hasMatchupDuration {
                        settings.matchupDuration = customDaySettings.matchupDuration
                    }
                    if customDaySettings.hasLocationTimeExclusivities {
                        settings.locationTimeExclusivities = customDaySettings.locationTimeExclusivities.locations.map({ BitSet64($0.times) })
                    }
                    if customDaySettings.hasLocationTravelDurations {
                        settings.locationTravelDurations = customDaySettings.locationTravelDurations.locations.map({ $0.travelDurationTo })
                    }
                    if customDaySettings.hasBalanceTimeStrictness {
                        settings.balanceTimeStrictness = customDaySettings.balanceTimeStrictness
                    }
                    if customDaySettings.hasBalanceLocationStrictness {
                        settings.balanceLocationStrictness = customDaySettings.balanceLocationStrictness
                    }
                    if customDaySettings.hasRedistributionSettings {
                        settings.redistributionSettings = customDaySettings.redistributionSettings
                        if let defaultSettings = general.redistributionSettings {
                            if !customDaySettings.redistributionSettings.hasMinMatchupsRequired, defaultSettings.hasMinMatchupsRequired {
                                settings.redistributionSettings!.minMatchupsRequired = defaultSettings.minMatchupsRequired
                            }
                            if !customDaySettings.redistributionSettings.hasMaxMovableMatchups, defaultSettings.hasMaxMovableMatchups {
                                settings.redistributionSettings!.maxMovableMatchups = defaultSettings.maxMovableMatchups
                            }
                        }
                    }
                    if customDaySettings.hasFlags {
                        settings.flags = customDaySettings.flags
                    }
                }
                settings.computeSettings(day: dayIndex, entries: entries)
                daySettings.append(.init(general: settings))
            }
        } else {
            for dayIndex in 0..<gameDays {
                var settings = general
                settings.computeSettings(day: dayIndex, entries: entries)
                daySettings.append(.init(general: settings))
            }
        }
        return daySettings
    }
}

// MARK: Validate settings
extension LeagueRequestPayload {
    @discardableResult
    private func validateSettings(
        kind: String,
        settings: LeagueGeneralSettings,
        fallbackSettings: LeagueGeneralSettings
    ) throws(LeagueError) -> GameGap? {
        let isDefault = kind == "default"
        if isDefault || settings.hasTimeSlots {
            guard settings.timeSlots > 0 else {
                throw .malformedInput(msg: "\(kind) 'timeSlots' size needs to be > 0")
            }
        }
        if settings.hasStartingTimes {
            guard settings.startingTimes.times.count > 0 else {
                throw .malformedInput(msg: "\(kind) 'startingTimes' size needs to be > 0")
            }
        }
        if settings.hasTimeSlots && settings.hasStartingTimes {
            guard settings.timeSlots == settings.startingTimes.times.count else {
                throw .malformedInput(msg: "\(kind) 'timeSlots' and 'startingTimes' size need to be equal")
            }
        }
        if isDefault || settings.hasLocations {
            guard settings.locations > 0 else {
                throw .malformedInput(msg: "\(kind) 'locations' needs to be > 0")
            }
        }
        if isDefault || settings.hasEntryMatchupsPerGameDay {
            guard settings.entryMatchupsPerGameDay > 0 else {
                throw .malformedInput(msg: "\(kind) 'entryMatchupsPerGameDay' needs to be > 0")
            }
        }
        if settings.hasMaximumPlayableMatchups {
            guard settings.maximumPlayableMatchups.array.count == entries.count else {
                throw .malformedInput(msg: "\(kind) 'maximumPlayableMatchups' size != \(entries.count)")
            }
        }
        if isDefault || settings.hasEntriesPerLocation {
            guard settings.entriesPerLocation > 0 else {
                throw .malformedInput(msg: "\(kind) 'entriesPerLocation' needs to be > 0")
            }
        }
        let locations = settings.hasLocations ? settings.locations : fallbackSettings.locations
        if settings.hasLocationTravelDurations {
            guard settings.locationTravelDurations.locations.count == locations else {
                throw .malformedInput(msg: "\(kind) 'locationTravelDurations.locations' size != \(locations)")
            }
        }
        if settings.hasLocationTimeExclusivities {
            guard settings.locationTimeExclusivities.locations.count == locations else {
                throw .malformedInput(msg: "\(kind) 'locationTimeExclusivities.locations' size != \(locations)")
            }
        }
        if settings.hasRedistributionSettings {
            if settings.redistributionSettings.hasMinMatchupsRequired {
                guard settings.redistributionSettings.minMatchupsRequired > 0 else {
                    throw .malformedInput(msg: "\(kind) redistribution setting 'minMatchupsRequired' needs to be > 0")
                }
            }
            if settings.redistributionSettings.hasMaxMovableMatchups {
                guard settings.redistributionSettings.maxMovableMatchups > 0 else {
                    throw .malformedInput(msg: "\(kind) redistribution setting 'maxMovableMatchups' needs to be > 0")
                }
            }
        }
        if isDefault || settings.hasGameGap {
            guard let gameGap = GameGap.init(htmlInputValue: settings.gameGap) else {
                throw .malformedInput(msg: "\(kind) invalid 'gameGap' value: \(settings.gameGap)")
            }
            return gameGap
        }
        return nil
    }
}

// MARK: Calculate maximum same opponent matchups cap
extension LeagueRequestPayload {
    func calculateMaximumSameOpponentMatchupsCap(
        entriesCount: Int
    ) throws(LeagueError) -> LeagueMaximumSameOpponentMatchupsCap {
        return try Self.calculateMaximumSameOpponentMatchupsCap(
            gameDays: gameDays,
            entryMatchupsPerGameDay: settings.entryMatchupsPerGameDay,
            entriesCount: entriesCount
        )
    }

    static func calculateMaximumSameOpponentMatchupsCap(
        gameDays: LeagueDayIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        entriesCount: Int
    ) throws(LeagueError) -> LeagueMaximumSameOpponentMatchupsCap {
        guard entriesCount > 1 else {
            throw .malformedInput(msg: "Number of teams need to be > 1 when calculating maximum same opponent matchups cap; got \(entriesCount)")
        }
        return LeagueMaximumSameOpponentMatchupsCap(
            ceil(
                Double(gameDays) / (Double(entriesCount-1) / Double(entryMatchupsPerGameDay))
            )
        )
    }
}

// MARK: Calculate max playable matchups
extension LeagueRequestPayload {
    static func calculateMaximumPlayableMatchups(
        gameDays: LeagueDayIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        teamsCount: Int,
        maximumPlayableMatchups: [UInt32]
    ) -> [UInt32] {
        if maximumPlayableMatchups.isEmpty {
            return .init(repeating: gameDays * entryMatchupsPerGameDay, count: teamsCount)
        } else if maximumPlayableMatchups.count != teamsCount {
            var array = [UInt32](repeating: gameDays * entryMatchupsPerGameDay, count: teamsCount)
            for i in 0..<min(teamsCount, maximumPlayableMatchups.count) {
                array[i] = maximumPlayableMatchups[i]
            }
            return array
        } else {
            return maximumPlayableMatchups
        }
    }
}