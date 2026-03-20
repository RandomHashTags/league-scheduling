
import OrderedCollections

#if canImport(SwiftGlibc)
import SwiftGlibc
#elseif canImport(Foundation)
import Foundation
#endif

// TODO: support divisions on the same day with different times
extension RequestPayload.Runtime {
    // MARK: Generate
    func generate() async -> LeagueGenerationResult {
        var err:String? = nil
        var results = [LeagueGenerationData]()
        do {
            results = try await generateSchedules()
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
extension RequestPayload.Runtime {
    private func generateSchedules() async throws -> [LeagueGenerationData] {
        #if LOG
        print("LeagueSchedule;generateSchedules;entries.count=\(entries.count)")
        #endif

        var maxStartingTimes:TimeIndex = 0
        var maxLocations:LocationIndex = 0
        for setting in daySettings {
            if setting.general.timeSlots > maxStartingTimes {
                maxStartingTimes = TimeIndex(setting.general.timeSlots)
            }
            if setting.general.locations > maxLocations {
                maxLocations = setting.general.locations
            }
        }

        guard constraints.hasDeterminism else {
            return try await generateSchedules(
                maxStartingTimes: maxStartingTimes,
                maxLocations: maxLocations,
                rng: SystemRandomNumberGenerator(),
                ScheduleConfig<
                    SystemRandomNumberGenerator,
                    Set<TimeIndex>,
                    Set<Entry.IDValue>,
                    Set<AvailableSlot>,
                    Set<MatchupPair>,
                    Set<Matchup>
                >.self
            )
        }
        switch constraints.determinism.technique {
        default:
            let seed = constraints.determinism.hasSeed ? constraints.determinism.seed : 1
            let multiplier = constraints.determinism.hasMultiplier ? constraints.determinism.multiplier : 6364136223846793005
            let increment = constraints.determinism.hasIncrement ? constraints.determinism.increment : 1442695040888963407
            return try await generateSchedules(
                maxStartingTimes: maxStartingTimes,
                maxLocations: maxLocations,
                rng: LCG(
                    seed: seed,
                    multiplier: multiplier,
                    increment: increment
                ),
                ScheduleConfig<
                    LCG,
                    OrderedSet<TimeIndex>,
                    OrderedSet<Entry.IDValue>,
                    OrderedSet<AvailableSlot>,
                    OrderedSet<MatchupPair>,
                    OrderedSet<Matchup>
                >.self
            )
        }
    }
    private func generateSchedules<Config: ScheduleConfiguration>(
        maxStartingTimes: TimeIndex,
        maxLocations: LocationIndex,
        rng: Config.RNG,
        _ config: Config.Type
    ) async throws -> [LeagueGenerationData] {
        var divisionEntries:ContiguousArray<Config.EntryIDSet> = .init(repeating: .init(), count: divisions.count)
        for entryIndex in 0..<entries.count {
            divisionEntries[unchecked: entries[entryIndex].division].insertMember(entries[entryIndex].id)
        }
        let maxSameOpponentMatchups = Self.maximumSameOpponentMatchups(
            gameDays: gameDays,
            entriesCount: entries.count,
            divisionEntries: divisionEntries,
            divisions: divisions
        )
        let dataSnapshot:LeagueScheduleDataSnapshot<Config> = .init(
            rng: rng,
            maxStartingTimes: maxStartingTimes,
            startingTimes: general.startingTimes,
            maxLocations: maxLocations,
            entriesPerMatchup: general.entriesPerLocation,
            maximumPlayableMatchups: general.maximumPlayableMatchups,
            entries: entries,
            divisionEntries: divisionEntries,
            matchupDuration: general.matchupDuration,
            gameGap: general.gameGap.minMax,
            sameLocationIfB2B: general.sameLocationIfB2B,
            locationTravelDurations: general.locationTravelDurations ?? .init(repeating: .init(repeating: 0, count: maxLocations), count: maxLocations),
            maxSameOpponentMatchups: maxSameOpponentMatchups
        )
        return try await generateDivisionSchedulesInParallel(
            divisionsCount: divisions.count,
            divisionEntries: divisionEntries,
            maxStartingTimes: maxStartingTimes,
            maxLocations: maxLocations,
            dataSnapshot: dataSnapshot
        )
    }
    private func generateDivisionSchedulesInParallel<Config: ScheduleConfiguration>(
        divisionsCount: Int,
        divisionEntries: ContiguousArray<Config.EntryIDSet>,
        maxStartingTimes: TimeIndex,
        maxLocations: LocationIndex,
        dataSnapshot: LeagueScheduleDataSnapshot<Config>
    ) async throws -> [LeagueGenerationData] {
        var grouped = [DayOfWeek:Config.EntryIDSet]()
        for (divisionID, division) in divisions.enumerated() {
            grouped[DayOfWeek(division.dayOfWeek), default: .init()].formUnion(divisionEntries[divisionID])
        }
        guard constraints.timeoutDelay > 0 else {
            return await withTaskGroup { group in
                for (dow, scheduledEntries) in grouped {
                    group.addTask {
                        return Self.generateSchedule(
                            dayOfWeek: dow,
                            settings: self,
                            dataSnapshot: dataSnapshot,
                            divisionsCount: divisionsCount,
                            maxStartingTimes: maxStartingTimes,
                            maxLocations: maxLocations,
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
            timeout: .seconds(constraints.timeoutDelay)
        ) { group in
            for (dow, scheduledEntries) in grouped {
                group.addTask {
                    return Self.generateSchedule(
                        dayOfWeek: dow,
                        settings: self,
                        dataSnapshot: dataSnapshot,
                        divisionsCount: divisionsCount,
                        maxStartingTimes: maxStartingTimes,
                        maxLocations: maxLocations,
                        scheduledEntries: scheduledEntries
                    )
                }
            }
        }
    }
}

// MARK: Timeout logic
extension RequestPayload.Runtime {
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
extension RequestPayload.Runtime {
    private static func generateSchedule<Config: ScheduleConfiguration>(
        dayOfWeek: DayOfWeek,
        settings: RequestPayload.Runtime,
        dataSnapshot: LeagueScheduleDataSnapshot<Config>,
        divisionsCount: Int,
        maxStartingTimes: TimeIndex,
        maxLocations: LocationIndex,
        scheduledEntries: Config.EntryIDSet
    ) -> LeagueGenerationData {
        let gameDays = settings.gameDays
        var generationData = LeagueGenerationData()
        generationData.assignLocationTimeRegenerationAttempts = 0
        generationData.negativeDayIndexRegenerationAttempts = 0
        generationData.schedule = .init(repeating: .init(), count: gameDays)

        var dataSnapshot = copy dataSnapshot
        var gameDayDivisionEntries:ContiguousArray<ContiguousArray<Config.EntryIDSet>> = .init(repeating: .init(repeating: .init(), count: divisionsCount), count: gameDays)
        loadMaxAllocations(
            dataSnapshot: &dataSnapshot,
            gameDayDivisionEntries: &gameDayDivisionEntries,
            settings: settings,
            maxStartingTimes: maxStartingTimes,
            maxLocations: maxLocations,
            scheduledEntries: scheduledEntries
        )

        var snapshots = [LeagueScheduleDataSnapshot<Config>]()
        snapshots.reserveCapacity(gameDays)
        var gameDayRegenerationAttempt:UInt32 = 0
        var day:DayIndex = 0
        var gameDaySettingValuesCount = 0
        var data = LeagueScheduleData(snapshot: dataSnapshot)
        while day < gameDays {
            if gameDaySettingValuesCount <= day {
                gameDaySettingValuesCount += 1
                let daySettings = settings.daySettings[unchecked: day].general
                let availableSlots:Config.AvailableSlotSet = Self.availableSlots(
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
                var set = Set<Matchup>(minimumCapacity: data.assignmentState.matchups.count)
                data.assignmentState.matchups.forEach { set.insert($0) } // TODO: optimize
                generationData.schedule[unchecked: day] = set
                snapshots.append(todayData)
                day += 1
                gameDayRegenerationAttempt = 0
            }
        }
        data.balanceHomeAway(generationData: &generationData)
        finalizeGenerationData(generationData: &generationData, data: data)
        return generationData
    }
    private static func finalizeGenerationData<Config: ScheduleConfiguration>(
        generationData: inout LeagueGenerationData,
        data: borrowing LeagueScheduleData<Config>
    ) {
        generationData.executionSteps = data.executionSteps
        generationData.shuffleHistory = data.shuffleHistory
    }
}

// MARK: Load max allocations
extension RequestPayload.Runtime {
    static func loadMaxAllocations<Config: ScheduleConfiguration>(
        dataSnapshot: inout LeagueScheduleDataSnapshot<Config>,
        gameDayDivisionEntries: inout ContiguousArray<ContiguousArray<Config.EntryIDSet>>,
        settings: borrowing RequestPayload.Runtime,
        maxStartingTimes: TimeIndex,
        maxLocations: LocationIndex,
        scheduledEntries: Config.EntryIDSet
    ) {
        scheduledEntries.forEach { entryIndex in
            let entry = settings.entries[unchecked: entryIndex]
            var maxPossiblePlayed:EntryMatchupsPerGameDay = 0
            var maxStartingTimesPlayedAt = 0
            var maxLocationsPlayedAt = 0
            //var maxPossiblePlayedForTimes = [TimeIndex](repeating: 0, count: maxStartingTimes)
            //var maxPossiblePlayedForLocations = [LocationIndex](repeating: 0, count: maxLocations)
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
                gameDayDivisionEntries[unchecked: day][unchecked: entry.division].insertMember(entry.id)
            }
            maxStartingTimesPlayedAt = max(maxStartingTimesPlayedAt, 1)
            maxLocationsPlayedAt = max(maxLocationsPlayedAt, 1)

            let defaultTimeNumber:TimeIndex = Self.balanceNumber(
                totalMatchupsPlayed: maxPossiblePlayed,
                value: maxStartingTimesPlayedAt,
                strictness: settings.general.balanceTimeStrictness
            )
            for time in 0..<maxStartingTimes {
                let timeNumber:TimeIndex
                if settings.general.balancedTimes.contains(TimeIndex(time)) {
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

            let defaultLocationNumber:LocationIndex = Self.balanceNumber(
                totalMatchupsPlayed: maxPossiblePlayed,
                value: maxLocationsPlayedAt,
                strictness: settings.general.balanceLocationStrictness
            )
            for location in 0..<maxLocations {
                let locationNumber:LocationIndex
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
extension RequestPayload.Runtime {
    static func optimalTimeSlots(
        availableTimeSlots: TimeIndex,
        locations: LocationIndex,
        matchupsCount: LocationIndex
    ) -> TimeIndex {
        var totalMatchupsPlayed:LocationIndex = 0
        var filledTimes:TimeIndex = 0
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
extension RequestPayload.Runtime {
    static func availableSlots<AvailableSlotSet: SetOfAvailableSlots>(
        times: TimeIndex,
        locations: LocationIndex,
        locationTimeExclusivity: [Set<TimeIndex>]?
    ) -> AvailableSlotSet {
        var slots = AvailableSlotSet()
        slots.reserveCapacity(Int(times) * locations)
        if let exclusivities = locationTimeExclusivity {
            for location in 0..<locations {
                if let timeExclusives = exclusivities[uncheckedPositive: location] {
                    for time in 0..<times {
                        if timeExclusives.contains(time) {
                            let slot = AvailableSlot(time: time, location: location)
                            slots.insertMember(slot)
                        }
                    }
                }
            }
        } else {
            for time in 0..<times {
                for location in 0..<locations {
                    let slot = AvailableSlot(time: time, location: location)
                    slots.insertMember(slot)
                }
            }
        }
        return slots
    }
}

// MARK: Get balance numbers
extension RequestPayload.Runtime {
    static func balanceNumber<T: FixedWidthInteger>(
        totalMatchupsPlayed: some FixedWidthInteger,
        value: some FixedWidthInteger,
        strictness: BalanceStrictness
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
extension RequestPayload.Runtime {
    static func maximumSameOpponentMatchups<EntryIDSet: SetOfEntryIDs>(
        gameDays: DayIndex,
        entriesCount: Int,
        divisionEntries: ContiguousArray<EntryIDSet>,
        divisions: [Division.Runtime]
    ) -> MaximumSameOpponentMatchups {
        var maxSameOpponentMatchups:MaximumSameOpponentMatchups = .init(repeating: .init(repeating: .max, count: entriesCount), count: entriesCount)
        for (divisionIndex, division) in divisions.enumerated() {
            let divisionEntries = divisionEntries[divisionIndex]
            let cap = division.maxSameOpponentMatchups
            divisionEntries.forEach { entryID in
                divisionEntries.forEach { opponentEntryID in
                    maxSameOpponentMatchups[unchecked: entryID][unchecked: opponentEntryID] = cap
                }
            }
        }
        return maxSameOpponentMatchups
    }
}