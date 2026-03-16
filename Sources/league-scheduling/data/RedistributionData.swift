
struct RedistributionData<Config: ScheduleConfiguration>: Sendable {
    /// The latest `DayIndex` that is allowed to redistribute matchups from.
    let startDayIndex:DayIndex
    let entryMatchupsPerGameDay:EntryMatchupsPerGameDay

    let minMatchupsRequired:Int
    let maxMovableMatchups:Int

    private var redistributedEntries:[UInt16]
    private(set) var redistributed:Set<Matchup>

    #if SpecializeScheduleConfiguration
    @_specialize(where Config == ScheduleConfig<BitSet64<DayIndex>, BitSet64<TimeIndex>, BitSet64<LocationIndex>, BitSet64<Entry.IDValue>>)
    @_specialize(where Config == ScheduleConfig<Set<DayIndex>, Set<TimeIndex>, Set<LocationIndex>, Set<Entry.IDValue>>)
    #endif
    init(
        dayIndex: DayIndex,
        startDayIndex: DayIndex,
        settings: LitLeagues_Leagues_RedistributionSettings?,
        data: borrowing LeagueScheduleData<Config>
    ) {
        self.startDayIndex = startDayIndex
        self.entryMatchupsPerGameDay = data.defaultMaxEntryMatchupsPerGameDay
        redistributedEntries = .init(repeating: 0, count: data.entriesCount)
        redistributed = []

        let threshold = (data.entriesCount / data.entriesPerMatchup)// * entryMatchupsPerGameDay
        var minMatchupsRequired = threshold
        var maxMovableMatchups = threshold
        if let r = settings {
            minMatchupsRequired = r.hasMinMatchupsRequired ? Int(r.minMatchupsRequired) : threshold
            maxMovableMatchups =  r.hasMaxMovableMatchups  ? Int(r.maxMovableMatchups)  : threshold
        }
        self.minMatchupsRequired = minMatchupsRequired
        self.maxMovableMatchups = maxMovableMatchups
    }
}

// MARK: Redistribute
extension RedistributionData {
    /// - Warning: Only moves previously assigned matchups to available slots for new day. DOES NOT SCHEDULE NEW MATCHUPS OR FILL ALL SLOTS FOR NEW DAY!
    /// - Returns: If redistributing matchups was successful.
    mutating func redistributeMatchups(
        clock: ContinuousClock,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        day: DayIndex,
        gameGap: GameGap.TupleValue,
        assignmentState: inout AssignmentState<Config>,
        executionSteps: inout [ExecutionStep],
        generationData: inout LeagueGenerationData
    ) -> Bool {
        let now = clock.now
        #if LOG
        print("redistributeMatchups;day=\(day)")
        #endif

        var assigned = 0
        var redistributables = Set<Redistributable>()
        for fromDayIndex in stride(from: startDayIndex, through: 0, by: -1) {
            for matchup in generationData.schedule[unchecked: fromDayIndex] {
                guard !redistributed.contains(matchup) else { continue }
                let homeAllowedTimes = assignmentState.entries[unchecked: matchup.home].gameTimes[unchecked: day]
                let awayAllowedTimes = assignmentState.entries[unchecked: matchup.away].gameTimes[unchecked: day]

                let homeAllowedLocations = assignmentState.entries[unchecked: matchup.home].gameLocations[unchecked: day]
                let awayAllowedLocations = assignmentState.entries[unchecked: matchup.away].gameLocations[unchecked: day]

                let homeMaxAssignedTimes = assignmentState.maxTimeAllocations[unchecked: matchup.home]
                let awayMaxAssignedTimes = assignmentState.maxTimeAllocations[unchecked: matchup.away]

                let homeMaxAssignedLocations = assignmentState.maxLocationAllocations[unchecked: matchup.home]
                let awayMaxAssignedLocations = assignmentState.maxLocationAllocations[unchecked: matchup.away]
                for slot in assignmentState.availableSlots {
                    assignmentState.decrementAssignData(home: matchup.home, away: matchup.away, slot: matchup.slot)
                    if canPlayAt.test(
                        time: slot.time,
                        location: slot.location,
                        allowedTimes: homeAllowedTimes,
                        allowedLocations: homeAllowedLocations,
                        playsAt: assignmentState.playsAt[unchecked: matchup.home],
                        playsAtTimes: assignmentState.playsAtTimes[unchecked: matchup.home],
                        playsAtLocations: assignmentState.playsAtLocations[unchecked: matchup.home],
                        timeNumber: assignmentState.assignedTimes[unchecked: matchup.home][unchecked: slot.time],
                        locationNumber: assignmentState.assignedLocations[unchecked: matchup.home][unchecked: slot.location],
                        maxTimeNumber: UInt8(homeMaxAssignedTimes[unchecked: slot.time]),
                        maxLocationNumber: UInt8(homeMaxAssignedLocations[unchecked: slot.location]),
                        gameGap: gameGap
                    ) && canPlayAt.test(
                        time: slot.time,
                        location: slot.location,
                        allowedTimes: awayAllowedTimes,
                        allowedLocations: awayAllowedLocations,
                        playsAt: assignmentState.playsAt[unchecked: matchup.away],
                        playsAtTimes: assignmentState.playsAtTimes[unchecked: matchup.away],
                        playsAtLocations: assignmentState.playsAtLocations[unchecked: matchup.away],
                        timeNumber: assignmentState.assignedTimes[unchecked: matchup.away][unchecked: slot.time],
                        locationNumber: assignmentState.assignedLocations[unchecked: matchup.away][unchecked: slot.location],
                        maxTimeNumber: UInt8(awayMaxAssignedTimes[unchecked: slot.time]),
                        maxLocationNumber: UInt8(awayMaxAssignedLocations[unchecked: slot.location]),
                        gameGap: gameGap
                    ) {
                        redistributables.insert(.init(fromDay: fromDayIndex, matchup: matchup, toSlot: slot))
                    }
                    assignmentState.incrementAssignData(home: matchup.home, away: matchup.away, slot: matchup.slot)
                }
            }
        }
        while (assigned < minMatchupsRequired || assigned < maxMovableMatchups) && !assignmentState.availableSlots.isEmpty {
            guard var redistributable = selectRedistributable(
                from: redistributables,
                assignmentState: assignmentState,
                generationData: generationData
            ) else { break }
            assigned += 1
            redistribute(
                redistributable: &redistributable,
                assignmentState: &assignmentState,
                generationData: &generationData
            )
            // filter redistributables so only the ones that can still play remain
            redistributables = redistributables.filter {
                assignmentState.availableSlots.contains($0.toSlot)
                && assignmentState.playsAt[unchecked: $0.matchup.home].count < entryMatchupsPerGameDay
                && assignmentState.playsAt[unchecked: $0.matchup.away].count < entryMatchupsPerGameDay
            }
        }
        #if LOG
        print("redistributeMatchups;day=\(day);assigned=\(assigned)")
        #endif
        let elapsedDuration = clock.now - now
        executionSteps.append(.init(key: "redistributeMatchups (\(day))", duration: elapsedDuration))
        return assignmentState.matchups.count >= minMatchupsRequired
    }
}

// MARK: Select redistributable
extension RedistributionData {
    private func selectRedistributable(
        from redistributables: Set<Redistributable>,
        assignmentState: borrowing AssignmentState<Config>,
        generationData: LeagueGenerationData
    ) -> Redistributable? {
        var redistributable:Redistributable? = nil

        // prioritize entries that have been redistributed the least
        var (cMin, cMax):(UInt16, UInt16) = (.max, .max)
        for r in redistributables {
            if generationData.schedule[unchecked: r.fromDay].count <= minMatchupsRequired {
                // don't take from the day since the matchups for it will render the day incomplete
                continue
            }
            let (rMin, rMax) = calculateMinMax(matchup: r.matchup)
            if rMin < cMin {
                redistributable = r
                (cMin, cMax) = (rMin, rMax)
            } else if rMin == cMin {
                if rMax <= cMax {
                    redistributable = r
                    (cMin, cMax) = (rMin, rMax)
                }
            }
        }
        return redistributable
    }
}

// MARK: Calculate min max
extension RedistributionData {
    private func calculateMinMax(
        matchup: Matchup
    ) -> (minimum: UInt16, maximum: UInt16) {
        let home = redistributedEntries[unchecked: matchup.home]
        let away = redistributedEntries[unchecked: matchup.away]
        return (
            min(home, away),
            max(home, away)
        )
    }
}

// MARK: Redistribute
extension RedistributionData {
    private mutating func redistribute(
        redistributable: inout Redistributable,
        assignmentState: inout AssignmentState<Config>,
        generationData: inout LeagueGenerationData
    ) {
        generationData.schedule[unchecked: redistributable.fromDay].remove(redistributable.matchup)
        assignmentState.decrementAssignData(home: redistributable.matchup.home, away: redistributable.matchup.away, slot: redistributable.matchup.slot)

        redistributed.insert(redistributable.matchup)
        redistributedEntries[unchecked: redistributable.matchup.home] += 1
        redistributedEntries[unchecked: redistributable.matchup.away] += 1
        redistributable.matchup.time = redistributable.toSlot.time
        redistributable.matchup.location = redistributable.toSlot.location
        assignmentState.matchups.insert(redistributable.matchup)
        assignmentState.availableSlots.remove(redistributable.toSlot)
        assignmentState.incrementAssignData(home: redistributable.matchup.home, away: redistributable.matchup.away, slot: redistributable.toSlot)
        assignmentState.insertPlaysAt(home: redistributable.matchup.home, away: redistributable.matchup.away, slot: redistributable.toSlot)
    }
}

// MARK: Redistributable
extension RedistributionData {
    private struct Redistributable: Hashable, Sendable {
        let fromDay:DayIndex
        var matchup:Matchup
        let toSlot:AvailableSlot
    }
}