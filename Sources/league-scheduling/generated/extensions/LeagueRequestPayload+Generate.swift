
import StaticDateTimes

#if canImport(SwiftGlibc)
import SwiftGlibc
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Generate
extension LeagueRequestPayload {
    public func generate() async throws(LeagueError) -> LeagueGenerationResult {
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
        return try await generate(
            defaultGameGap: defaultGameGap,
            divisionsCount: divisionsCount,
            startingDayOfWeek: startingDayOfWeek
        )
    }
}

extension LeagueRequestPayload {
    private func generate(
        defaultGameGap: GameGap,
        divisionsCount: Int,
        startingDayOfWeek: LeagueDayOfWeek
    ) async throws(LeagueError) -> LeagueGenerationResult {
        switch settings.timeSlots {
        case 1...64:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                t: BitSet64<LeagueTimeIndex>()
            )
        case 1...128:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                t: BitSet128<LeagueTimeIndex>()
            )
        default:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                t: Set<LeagueTimeIndex>()
            )
        }
    }
    private func generate<Times: SetOfTimeIndexes>(
        defaultGameGap: GameGap,
        divisionsCount: Int,
        startingDayOfWeek: LeagueDayOfWeek,
        t: Times,
    ) async throws(LeagueError) -> LeagueGenerationResult {
        switch settings.locations {
        case 1...64:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                defaultTimes: t,
                defaultLocations: BitSet64<LeagueLocationIndex>()
            )
        case 65...128:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                defaultTimes: t,
                defaultLocations: BitSet128<LeagueLocationIndex>()
            )
        default:
            return try await generate(
                defaultGameGap: defaultGameGap,
                divisionsCount: divisionsCount,
                startingDayOfWeek: startingDayOfWeek,
                defaultTimes: t,
                defaultLocations: Set<LeagueLocationIndex>()
            )
        }
    }
}

extension LeagueRequestPayload {
    private func generate<Times: SetOfTimeIndexes, Locations: SetOfLocationIndexes>(
        defaultGameGap: GameGap,
        divisionsCount: Int,
        startingDayOfWeek: LeagueDayOfWeek,
        defaultTimes: Times,
        defaultLocations: Locations
    ) async throws(LeagueError) -> LeagueGenerationResult {
        let divisionDefaults:DivisionDefaults<Times, Locations> = loadDivisionDefaults(divisionsCount: divisionsCount)
        var teamsForDivision = [Int](repeating: 0, count: divisionsCount)
        let entries = try parseEntries(
            divisionsCount: divisionsCount,
            teams: entries,
            teamsForDivision: &teamsForDivision,
            divisionDefaults: divisionDefaults
        )
        let divisions = try parseDivisions(
            divisionsCount: divisionsCount,
            locations: settings.locations,
            divisionGameDays: divisionDefaults.gameDays,
            defaultGameGap: defaultGameGap,
            fallbackDayOfWeek: startingDayOfWeek,
            teamsForDivision: teamsForDivision
        )
        let correctMaximumPlayableMatchups = Self.calculateMaximumPlayableMatchups(
            gameDays: gameDays,
            entryMatchupsPerGameDay: settings.entryMatchupsPerGameDay,
            teamsCount: entries.count,
            maximumPlayableMatchups: settings.maximumPlayableMatchups.array
        )

        let timesSet = Times(0..<settings.timeSlots)
        var defaultTimeExclusivities = Array(repeating: timesSet, count: settings.locations)
        if settings.hasLocationTimeExclusivities {
            for (location, exclusivities) in settings.locationTimeExclusivities.locations.enumerated() {
                if !exclusivities.times.isEmpty {
                    defaultTimeExclusivities[unchecked: location] = .init(exclusivities.times)
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
        var balancedTimes:Times
        var balancedLocations:Locations
        if settings.balanceTimeStrictness != .lenient {
            balancedTimes = timesSet
        } else {
            balancedTimes = defaultTimes
        }
        if settings.balanceLocationStrictness != .lenient {
            balancedLocations = Locations(0..<settings.locations)
        } else {
            balancedLocations = defaultLocations
        }
        return try await generate(
            divisions: divisions,
            entries: entries,
            correctMaximumPlayableMatchups: correctMaximumPlayableMatchups,
            general: LeagueGeneralSettings.Runtime<ScheduleConfig<Times, Locations>>(
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
        )
    }
}

extension LeagueRequestPayload {
    private func generate<Config: ScheduleConfiguration>(
        divisions: [LeagueDivision.Runtime],
        entries: [Config.EntryRuntime],
        correctMaximumPlayableMatchups: [UInt32],
        general: LeagueGeneralSettings.Runtime<Config>
    ) async throws(LeagueError) -> LeagueGenerationResult {
        let daySettings = try parseDaySettings(
            general: general,
            correctMaximumPlayableMatchups: correctMaximumPlayableMatchups,
            entries: entries
        )
        return await LeagueSchedule.generate(LeagueRequestPayload.Runtime(
            gameDays: gameDays,
            divisions: divisions,
            entries: entries,
            general: general,
            daySettings: daySettings
        ))
    }
}

// MARK: Division defaults
extension LeagueRequestPayload {
    struct DivisionDefaults<Times: SetOfTimeIndexes, Locations: SetOfLocationIndexes>: Sendable, ~Copyable {
        let gameDays:[Set<LeagueDayIndex>]
        let byes:[Set<LeagueDayIndex>]
        let gameTimes:[[Times]]
        let gameLocations:[[Locations]]
    }
}

// MARK: Load division defaults
extension LeagueRequestPayload {
    private func loadDivisionDefaults<
        Times: SetOfTimeIndexes,
        Locations: SetOfLocationIndexes
    >(
        divisionsCount: Int
    ) -> DivisionDefaults<Times, Locations> {
        var gameDays = [Set<LeagueDayIndex>]()
        var byes = [Set<LeagueDayIndex>]()
        var gameTimes = [[Times]]()
        var gameLocations = [[Locations]]()
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
                    var dgdt = [Times]()
                    for gameDay in 0..<self.gameDays {
                        let times = getTimesFunc(self, gameDay, settings.timeSlots)
                        dgdt.append(.init(0..<times))
                    }
                    gameTimes.append(dgdt)
                }
                if division.hasGameDayLocations {
                    gameLocations.append(division.gameDayLocations.locations.map({ .init($0.locations) }))
                } else {
                    var dgdl = [Locations]()
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

            var dgdt = [Times]()
            for gameDay in 0..<self.gameDays {
                let times = getTimesFunc(self, gameDay, settings.timeSlots)
                dgdt.append(.init(0..<times))
            }
            gameTimes.append(dgdt)

            var dgdl = [Locations]()
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
    private func parseEntries<Times: SetOfTimeIndexes, Locations: SetOfLocationIndexes>(
        divisionsCount: Int,
        teams: [LeagueEntry],
        teamsForDivision: inout [Int],
        divisionDefaults: borrowing DivisionDefaults<Times, Locations>
    ) throws(LeagueError) -> [LeagueEntry.Runtime<Times, Locations>] {
        var entries = [LeagueEntry.Runtime<Times, Locations>]()
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
    private func parseDaySettings<Config: ScheduleConfiguration>(
        general: LeagueGeneralSettings.Runtime<Config>,
        correctMaximumPlayableMatchups: [UInt32],
        entries: [Config.EntryRuntime]
    ) throws(LeagueError) -> [LeagueGeneralSettings.Runtime<Config>] {
        var daySettings = [LeagueGeneralSettings.Runtime<Config>]()
        daySettings.reserveCapacity(gameDays)
        if hasIndividualDaySettings {
            for dayIndex in 0..<gameDays {
                var settings = general
                let targetDaySettings = individualDaySettings.days[unchecked: dayIndex]
                if targetDaySettings.hasSettings {
                    settings.apply(
                        gameDays: gameDays, entriesCount: entries.count,
                        correctMaximumPlayableMatchups: correctMaximumPlayableMatchups,
                        general: general,
                        customDaySettings: targetDaySettings.settings
                    )
                }
                settings.computeSettings(day: dayIndex, entries: entries)
                daySettings.append(settings)
            }
        } else {
            for dayIndex in 0..<gameDays {
                var settings = general
                settings.computeSettings(day: dayIndex, entries: entries)
                daySettings.append(settings)
            }
        }
        return daySettings
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