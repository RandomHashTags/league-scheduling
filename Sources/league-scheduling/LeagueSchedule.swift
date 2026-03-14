
#if canImport(SwiftGlibc)
import SwiftGlibc
#elseif canImport(Foundation)
import Foundation
#endif

// TODO: support divisions on the same day with different times
struct LeagueSchedule: Sendable, ~Copyable {
    /// Settings for this schedule.
    let settings:LeagueRequestPayload.Runtime

    // MARK: Generate
    func generate() async -> LeagueGenerationResult {
        var err:String? = nil
        var results = [LeagueGenerationData]()
        do {
            results = try await generateSchedules(settings: settings)
            for result in results {
                if let error = result.error {
                    if err == nil {
                        err = "\(error)"
                    } else {
                        err! += "\n\(error)"
                    }
                }
            }
        } catch {
            err = "\(error)"
        }
        return .init(
            results: results,
            error: err
        )
    }
}

// MARK: Generate schedules
extension LeagueSchedule {
    func generateSchedules(
        settings: LeagueRequestPayload.Runtime
    ) async throws -> [LeagueGenerationData] {
        let divisionsCount = settings.divisions.count
        var divisionEntries:ContiguousArray<Set<LeagueEntry.IDValue>> = .init(repeating: Set(), count: divisionsCount)
        #if LOG
        print("LeagueSchedule;generateSchedules;divisionsCount=\(divisionsCount);settings.entries.count=\(settings.entries.count)")
        #endif
        for entryIndex in 0..<settings.entries.count {
            divisionEntries[unchecked: settings.entries[entryIndex].division].insert(settings.entries[entryIndex].id)
        }

        var maxStartingTimes:LeagueTimeIndex = 0
        var maxLocations:LeagueLocationIndex = 0
        for setting in settings.daySettings {
            if setting.general.timeSlots > maxStartingTimes {
                maxStartingTimes = LeagueTimeIndex(setting.general.timeSlots)
            }
            if setting.general.locations > maxLocations {
                maxLocations = setting.general.locations
            }
        }

        let maxSameOpponentMatchups = Self.maximumSameOpponentMatchups(
            gameDays: settings.gameDays,
            entriesCount: settings.entries.count,
            divisionEntries: divisionEntries,
            divisions: settings.divisions
        )
        let dataSnapshot = LeagueScheduleDataSnapshot(
            maxStartingTimes: maxStartingTimes,
            startingTimes: settings.general.startingTimes,
            maxLocations: maxLocations,
            entriesPerMatchup: settings.general.entriesPerLocation,
            maximumPlayableMatchups: settings.general.maximumPlayableMatchups,
            entries: settings.entries,
            divisionEntries: divisionEntries,
            matchupDuration: settings.general.matchupDuration,
            gameGap: settings.general.gameGap.minMax,
            sameLocationIfB2B: settings.general.sameLocationIfB2B,
            locationTravelDurations: settings.general.locationTravelDurations ?? .init(repeating: .init(repeating: 0, count: maxLocations), count: maxLocations),
            maxSameOpponentMatchups: maxSameOpponentMatchups
        )
        var grouped = [LeagueDayOfWeek:Set<LeagueEntry.IDValue>]()
        for (divisionID, division) in settings.divisions.enumerated() {
            grouped[LeagueDayOfWeek(division.dayOfWeek), default: []].formUnion(divisionEntries[divisionID])
        }
        let finalMaxStartingTimes = maxStartingTimes
        let finalMaxLocations = maxLocations
        guard settings.constraints.timeoutDelay > 0 else {
            return await withTaskGroup { group in
                for (dow, scheduledEntries) in grouped {
                    group.addTask {
                        return Self.generateSchedule(
                            dayOfWeek: dow,
                            settings: settings,
                            dataSnapshot: dataSnapshot,
                            divisionsCount: divisionsCount,
                            maxStartingTimes: finalMaxStartingTimes,
                            maxLocations: finalMaxLocations,
                            scheduledEntries: scheduledEntries
                        )
                    }
                }
                var results = [LeagueGenerationData]()
                results.reserveCapacity(grouped.count)
                for await r in group {
                    results.append(r)
                }
                return results
            }
        }
        return try await withTimeout(
            key: "generateSchedules",
            resultCount: grouped.count,
            timeout: .seconds(settings.constraints.timeoutDelay)
        ) { group in
            for (dow, scheduledEntries) in grouped {
                group.addTask {
                    return Self.generateSchedule(
                        dayOfWeek: dow,
                        settings: settings,
                        dataSnapshot: dataSnapshot,
                        divisionsCount: divisionsCount,
                        maxStartingTimes: finalMaxStartingTimes,
                        maxLocations: finalMaxLocations,
                        scheduledEntries: scheduledEntries
                    )
                }
            }
        }
    }
}

// MARK: Timeout logic
extension LeagueSchedule {
    func withTimeout<T>(
        key: String,
        resultCount: Int,
        timeout: Duration,
        code: (inout ThrowingTaskGroup<T, any Error>) -> Void
    ) async throws -> [T] {
        do {
            return try await withThrowingTaskGroup(of: T.self, body: { group in
                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw LeagueError.timedOut(function: key)
                }
                code(&group)
                var completed = 0
                var results = [T]()
                results.reserveCapacity(resultCount)
                do {
                    for try await result in group {
                        completed += 1
                        results.append(result)
                        if completed == resultCount {
                            group.cancelAll()
                            break
                        }
                    }
                } catch {
                    group.cancelAll()
                    throw error
                }
                return results
            })
        } catch {
            guard !(error is CancellationError) else { return [] }
            throw error
        }
    }
}

// MARK: Generate schedule
extension LeagueSchedule {
    private static func generateSchedule(
        dayOfWeek: LeagueDayOfWeek,
        settings: LeagueRequestPayload.Runtime,
        dataSnapshot: LeagueScheduleDataSnapshot,
        divisionsCount: Int,
        maxStartingTimes: LeagueTimeIndex,
        maxLocations: LeagueLocationIndex,
        scheduledEntries: Set<LeagueEntry.IDValue>
    ) -> LeagueGenerationData {
        let gameDays = settings.gameDays
        var generationData = LeagueGenerationData()
        generationData.assignLocationTimeRegenerationAttempts = 0
        generationData.negativeDayIndexRegenerationAttempts = 0
        generationData.schedule = .init(repeating: Set(), count: gameDays)

        var dataSnapshot = copy dataSnapshot
        var gameDayDivisionEntries:ContiguousArray<ContiguousArray<Set<LeagueEntry.IDValue>>> = .init(repeating: .init(repeating: Set(), count: divisionsCount), count: gameDays)
        loadMaxAllocations(
            dataSnapshot: &dataSnapshot,
            gameDayDivisionEntries: &gameDayDivisionEntries,
            settings: settings,
            maxStartingTimes: maxStartingTimes,
            maxLocations: maxLocations,
            scheduledEntries: scheduledEntries
        )

        var snapshots = [LeagueScheduleDataSnapshot]()
        snapshots.reserveCapacity(gameDays)
        var gameDayRegenerationAttempt:UInt32 = 0
        var day:LeagueDayIndex = 0
        var gameDaySettingValuesCount = 0
        var data = LeagueScheduleData(snapshot: dataSnapshot)
        while day < gameDays {
            if gameDaySettingValuesCount <= day {
                gameDaySettingValuesCount += 1
                let daySettings = settings.daySettings[unchecked: day].general
                let availableSlots = LeagueSchedule.availableSlots(
                    times: daySettings.timeSlots,
                    locations: daySettings.locations,
                    locationTimeExclusivity: daySettings.locationTimeExclusivities
                )
                do throws(LeagueError) {
                    try data.newDay(
                        day: day,
                        daySettings: daySettings,
                        divisionEntries: gameDayDivisionEntries[unchecked: day],
                        availableSlots: availableSlots,
                        settings: settings,
                        generationData: &generationData
                    )
                } catch {
                    generationData.error = error
                    finalizeGenerationData(generationData: &generationData, data: data)
                    return generationData
                }
            }
            let todayData = data.snapshot()
            var assignedSlots = false
            do throws(LeagueError) {
                if data.redistributedMatchups {
                    assignedSlots = true
                } else {
                    assignedSlots = try data.assignSlots()
                }
            } catch {
                generationData.error = error
                finalizeGenerationData(generationData: &generationData, data: data)
                return generationData
            }
            if !assignedSlots {
                guard generationData.assignLocationTimeRegenerationAttempts != settings.constraints.regenerationAttemptsThreshold else {
                    generationData.error = LeagueError.failedAssignment(
                        regenerationAttemptsThreshold: settings.constraints.regenerationAttemptsThreshold,
                        balanceTimeStrictness: settings.general.balanceTimeStrictness
                    )
                    finalizeGenerationData(generationData: &generationData, data: data)
                    return generationData
                }
                generationData.assignLocationTimeRegenerationAttempts += 1
                generationData.schedule[unchecked: day].removeAll(keepingCapacity: true)
                gameDayRegenerationAttempt += 1
                if gameDayRegenerationAttempt == settings.constraints.regenerationAttemptsForConsecutiveDay {
                    if day == 0 {
                        guard generationData.negativeDayIndexRegenerationAttempts != settings.constraints.regenerationAttemptsForFirstDay else {
                            generationData.error = LeagueError.failedNegativeDayIndex
                            finalizeGenerationData(generationData: &generationData, data: data)
                            return generationData
                        }
                        generationData.negativeDayIndexRegenerationAttempts += 1
                        data.loadSnapshot(todayData)
                    } else {
                        day -= 1
                        data.loadSnapshot(snapshots[unchecked: day])
                        snapshots.removeLast()
                        generationData.schedule[unchecked: day].removeAll(keepingCapacity: true)
                        gameDaySettingValuesCount -= 1
                    }
                    gameDayRegenerationAttempt = 0
                } else {
                    #if LOG
                    print("failed to assign slots for day \(day)")
                    generationData.schedule[unchecked: day] = data.assignmentState.matchups
                    break;
                    #endif
                    
                    data.loadSnapshot(todayData)
                }
            } else {
                generationData.schedule[unchecked: day] = data.assignmentState.matchups
                snapshots.append(todayData)
                day += 1
                gameDayRegenerationAttempt = 0
            }
        }
        finalizeGenerationData(generationData: &generationData, data: data)
        return generationData
    }
    private static func finalizeGenerationData(
        generationData: inout LeagueGenerationData,
        data: borrowing LeagueScheduleData
    ) {
        #if UnitTesting
        generationData.assignedTimes = data.assignmentState.assignedTimes
        generationData.assignedLocations = data.assignmentState.assignedLocations
        generationData.assignedEntryHomeAways = data.assignmentState.assignedEntryHomeAways
        //generationData.assignedHomeAways = data.assignmentState.assignedHomeAways
        generationData.maxTimeAllocations = data.assignmentState.maxTimeAllocations
        generationData.maxLocationAllocations = data.assignmentState.maxLocationAllocations
        #endif

        generationData.executionSteps = data.executionSteps
        generationData.shuffleHistory = data.shuffleHistory
    }
}

// MARK: Load max allocations
extension LeagueSchedule {
    static func loadMaxAllocations(
        dataSnapshot: inout LeagueScheduleDataSnapshot,
        gameDayDivisionEntries: inout ContiguousArray<ContiguousArray<Set<LeagueEntry.IDValue>>>,
        settings: borrowing LeagueRequestPayload.Runtime,
        maxStartingTimes: LeagueTimeIndex,
        maxLocations: LeagueLocationIndex,
        scheduledEntries: Set<LeagueEntry.IDValue>
    ) {
        for entryIndex in scheduledEntries {
            let entry = settings.entries[unchecked: entryIndex]
            var maxPossiblePlayed:LeagueEntryMatchupsPerGameDay = 0
            var maxStartingTimesPlayedAt = 0
            var maxLocationsPlayedAt = 0
            //var maxPossiblePlayedForTimes = [LeagueTimeIndex](repeating: 0, count: maxStartingTimes)
            //var maxPossiblePlayedForLocations = [LeagueLocationIndex](repeating: 0, count: maxLocations)
            for day in 0..<settings.gameDays {
                guard entry.gameDays.contains(day) && !entry.byes.contains(day) else { continue }
                let daySettings = settings.daySettings[unchecked: day].general
                let entryMaxMatchupsForDay = entry.maxMatchupsForGameDay(
                    day: day,
                    fallback: daySettings.defaultMaxEntryMatchupsPerGameDay
                )
                maxPossiblePlayed += entryMaxMatchupsForDay

                let allowedGameTimes = entry.gameTimes[unchecked: day]
                let allowedGameLocations = entry.gameLocations[unchecked: day]
                var playable = 0
                for t in 0..<daySettings.timeSlots {
                    if allowedGameTimes.contains(t) {
                        playable += 1
                        //maxPossiblePlayedForTimes[t] += entryMaxMatchupsForDay
                    }
                }
                maxStartingTimesPlayedAt = max(maxStartingTimesPlayedAt, playable)
                playable = 0
                for l in 0..<daySettings.locations {
                    if allowedGameLocations.contains(l) {
                        playable += 1
                        //maxPossiblePlayedForLocations[unchecked: l] += entryMaxMatchupsForDay
                    }
                }
                maxLocationsPlayedAt = max(maxLocationsPlayedAt, playable)
                gameDayDivisionEntries[unchecked: day][unchecked: entry.division].insert(entry.id)
            }
            maxStartingTimesPlayedAt = max(maxStartingTimesPlayedAt, 1)
            maxLocationsPlayedAt = max(maxLocationsPlayedAt, 1)

            let defaultTimeNumber:LeagueTimeIndex = Self.balanceNumber(
                totalMatchupsPlayed: maxPossiblePlayed,
                value: maxStartingTimesPlayedAt,
                strictness: settings.general.balanceTimeStrictness
            )
            for time in 0..<maxStartingTimes {
                let timeNumber:LeagueTimeIndex
                if settings.general.balancedTimes.contains(LeagueTimeIndex(time)) {
                    timeNumber = defaultTimeNumber
                    /*timeNumber = Self.balanceNumber(
                        totalMatchupsPlayed: maxPossiblePlayedForTimes[unchecked: time],
                        value: maxStartingTimesPlayedAt,
                        strictness: settings.general.balanceTimeStrictness
                    )*/
                } else {
                    timeNumber = .max
                }
                dataSnapshot.assignmentState.maxTimeAllocations[unchecked: entryIndex][unchecked: time] = timeNumber
            }

            let defaultLocationNumber:LeagueLocationIndex = Self.balanceNumber(
                totalMatchupsPlayed: maxPossiblePlayed,
                value: maxLocationsPlayedAt,
                strictness: settings.general.balanceLocationStrictness
            )
            for location in 0..<maxLocations {
                let locationNumber:LeagueLocationIndex
                if settings.general.balancedLocations.contains(location) {
                    locationNumber = defaultLocationNumber
                    /*locationNumber = Self.balanceNumber(
                        totalMatchupsPlayed: maxPossiblePlayedForLocations[unchecked: location],
                        value: maxLocationsPlayedAt,
                        strictness: settings.general.balanceLocationStrictness
                    )*/
                } else {
                    locationNumber = .max
                }
                dataSnapshot.assignmentState.maxLocationAllocations[unchecked: entryIndex][unchecked: location] = locationNumber
            }

            #if LOG
            print("LeagueSchedule;loadMaxAllocations;entryIndex=\(entryIndex);dataSnapshot.assignmentState.maxTimeAllocations=\(dataSnapshot.assignmentState.maxTimeAllocations);dataSnapshot.assignmentState.maxLocationAllocations=\(dataSnapshot.assignmentState.maxLocationAllocations)")
            #endif
        }
    }
}

// MARK: Optimal time slots
extension LeagueSchedule {
    static func optimalTimeSlots(
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
}

// MARK: Get available slots
extension LeagueSchedule {
    static func availableSlots(
        times: LeagueTimeIndex,
        locations: LeagueLocationIndex,
        locationTimeExclusivity: [Set<LeagueTimeIndex>]?
    ) -> Set<LeagueAvailableSlot> {
        var slots = Set<LeagueAvailableSlot>(minimumCapacity: times * locations)
        if let exclusivities = locationTimeExclusivity {
            for location in 0..<locations {
                if let timeExclusives = exclusivities[uncheckedPositive: location] {
                    for time in 0..<times {
                        if timeExclusives.contains(time) {
                            let slot = LeagueAvailableSlot(time: time, location: location)
                            slots.insert(slot)
                        }
                    }
                }
            }
        } else {
            for time in 0..<times {
                for location in 0..<locations {
                    let slot = LeagueAvailableSlot(time: time, location: location)
                    slots.insert(slot)
                }
            }
        }
        return slots
    }
}

// MARK: Get balance numbers
extension LeagueSchedule {
    static func balanceNumber<T: FixedWidthInteger>(
        totalMatchupsPlayed: some FixedWidthInteger,
        value: some FixedWidthInteger,
        strictness: LeagueBalanceStrictness
    ) -> T {
        guard strictness != .lenient else { return .max }
        var minimumValue = T(ceil(Double(totalMatchupsPlayed) / Double(value)))
        switch strictness {
        case .lenient:      minimumValue = .max
        case .normal:       minimumValue += 1
        case .relaxed:      minimumValue += 2
        case .very:         break
        case .UNRECOGNIZED: break
        }
        return minimumValue
    }
}

// MARK: Maximum same opponent matchups
extension LeagueSchedule {
    static func maximumSameOpponentMatchups(
        gameDays: LeagueDayIndex,
        entriesCount: Int,
        divisionEntries: ContiguousArray<Set<LeagueEntry.IDValue>>,
        divisions: [LeagueDivision.Runtime]
    ) -> LeagueMaximumSameOpponentMatchups {
        var maxSameOpponentMatchups:LeagueMaximumSameOpponentMatchups = .init(repeating: .init(repeating: .max, count: entriesCount), count: entriesCount)
        for (divisionIndex, division) in divisions.enumerated() {
            let divisionEntries = divisionEntries[divisionIndex]
            let cap = division.maxSameOpponentMatchups
            for entryID in divisionEntries {
                for opponentEntryID in divisionEntries {
                    maxSameOpponentMatchups[unchecked: entryID][unchecked: opponentEntryID] = cap
                }
            }
        }
        return maxSameOpponentMatchups
    }
}