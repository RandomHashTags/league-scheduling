
import struct FoundationEssentials.Date
@testable import LeagueScheduling
import StaticDateTimes

protocol ScheduleTestsProtocol: ScheduleExpectations {
    typealias UnitTestScheduleConfig = ScheduleConfig<
        SystemRandomNumberGenerator,
        BitSet64<DayIndex>,
        BitSet64<TimeIndex>,
        BitSet64<LocationIndex>,
        BitSet64<Entry.IDValue>,
        Set<AvailableSlot>,
        Set<MatchupPair>,
        Set<Matchup>,
        Set<RedistributableMatchup>,
        Set<FlippableMatchup>
    >
    typealias UnitTestRuntimeSchedule = RequestPayload.Runtime<UnitTestScheduleConfig>
}

// MARK: Get entries
extension ScheduleTestsProtocol {
    static func getEntries(
        divisions: [Division.IDValue],
        gameDays: DayIndex,
        times: TimeIndex,
        locations: LocationIndex,
        teams: Int,
        homeLocations: ContiguousArray<UnitTestScheduleConfig.LocationSet> = [],
        byes: ContiguousArray<UnitTestScheduleConfig.DaySet> = []
    ) -> [UnitTestScheduleConfig.EntryRuntime] {
        let playsOn = Array(repeating: UnitTestScheduleConfig.DaySet(0..<gameDays), count: teams)
        let playsAtTimes = Array(repeating: Array(repeating: UnitTestScheduleConfig.TimeSet(0..<times), count: gameDays), count: teams)
        let playsAtLocations = Array(repeating: Array(repeating: UnitTestScheduleConfig.LocationSet(0..<locations), count: gameDays), count: teams)
        var entries = [UnitTestScheduleConfig.EntryRuntime]()
        entries.reserveCapacity(teams)
        for division in divisions {
            let entry = Entry.Runtime(
                id: Entry.IDValue(entries.count),
                division: division,
                gameDays: playsOn[entries.count],
                gameTimes: playsAtTimes[entries.count],
                gameLocations: playsAtLocations[entries.count],
                homeLocations: homeLocations[uncheckedPositive: entries.count] ?? .init(),
                byes: byes[uncheckedPositive: entries.count] ?? .init(),
                matchupsPerGameDay: nil
            )
            entries.append(entry)
        }
        return entries
    }
}

extension ScheduleTestsProtocol {
    static func getDivision(
        dayOfWeek: DayOfWeek,
        gameGaps: [GameGap] = [],
        values: (
            gameDays: DayIndex,
            entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
            entriesCount: Int
        )
    ) throws(LeagueError) -> UnitTestScheduleConfig.DivisionRuntime {
        let maxSameOpponentMatchups = try calculateMaximumSameOpponentMatchupsCap(
            gameDays: values.gameDays,
            entryMatchupsPerGameDay: values.entryMatchupsPerGameDay,
            entriesCount: values.entriesCount
        )
        return .init(
            dayOfWeek: dayOfWeek,
            gameDays: .init(0..<values.gameDays),
            gameGaps: gameGaps,
            maxSameOpponentMatchups: maxSameOpponentMatchups
        )
    }
}

// MARK: Get schedule
extension ScheduleTestsProtocol {
    static func getSchedule(
        gameDays: DayIndex,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32] = [],
        entriesPerLocation: EntriesPerMatchup,
        matchupDuration: MatchupDuration = 0,
        startingTimes: [StaticTime],
        locations: LocationIndex,
        optimizeTimes: Bool,
        prioritizeEarlierTimes: Bool = true,
        prioritizeHomeAway: Bool,
        balanceHomeAway: Bool = true,
        sameLocationIfB2B: Bool = false,
        redistributionSettings: LitLeagues_Leagues_RedistributionSettings? = nil,
        balanceTimeStrictness: BalanceStrictness,
        balanceLocationStrictness: BalanceStrictness,
        gameGaps: GameGap,
        divisions: [UnitTestScheduleConfig.DivisionRuntime],
        divisionsCanPlayOnSameDay: Bool = true,
        divisionsCanPlayAtSameTime: Bool = true,
        entries: [UnitTestScheduleConfig.EntryRuntime],
        constraints: GenerationConstraints = .default
    ) -> RequestPayload.Runtime<UnitTestScheduleConfig> {
        let correctMaximumPlayableMatchups = RequestPayload.calculateMaximumPlayableMatchups(
            gameDays: gameDays,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            teamsCount: entries.count,
            maximumPlayableMatchups: maximumPlayableMatchups
        )
        let times:TimeIndex = TimeIndex(startingTimes.count)
        let timeSlots:UnitTestScheduleConfig.TimeSet = .init(0..<times)
        let matchupSlots:UnitTestScheduleConfig.LocationSet = .init(0..<locations)
        let generalSettings = GeneralSettings.Runtime<UnitTestScheduleConfig>.init(
            gameGap: gameGaps,
            timeSlots: TimeIndex(startingTimes.count),
            startingTimes: startingTimes,
            entriesPerLocation: entriesPerLocation,
            locations: locations,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            maximumPlayableMatchups: correctMaximumPlayableMatchups,
            matchupDuration: matchupDuration,
            locationTimeExclusivities: nil,
            locationTravelDurations: nil,
            balanceTimeStrictness: balanceTimeStrictness,
            balancedTimes: timeSlots,
            balanceLocationStrictness: balanceLocationStrictness,
            balancedLocations: matchupSlots,
            redistributionSettings: redistributionSettings,
            flags: SettingFlags.get(
                optimizeTimes: optimizeTimes,
                prioritizeEarlierTimes: prioritizeEarlierTimes,
                prioritizeHomeAway: prioritizeHomeAway,
                balanceHomeAway: balanceHomeAway,
                sameLocationIfB2B: sameLocationIfB2B
            )
        )
        
        var daySettings = [GeneralSettings.Runtime<UnitTestScheduleConfig>]()
        daySettings.reserveCapacity(gameDays)
        for day in 0..<gameDays {
            var settings = generalSettings
            settings.computeSettings(day: day, entries: entries)
            daySettings.append(settings)
        }
        return .init(
            rng: .init(),
            constraints: constraints,
            gameDays: gameDays,
            divisions: divisions,
            entries: entries,
            general: generalSettings,
            daySettings: daySettings
        )
    }
}