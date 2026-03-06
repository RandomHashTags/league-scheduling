
import struct FoundationEssentials.Date
@testable import LeagueScheduling
import StaticDateTimes

protocol ScheduleTestsProtocol: ScheduleExpectations {
}

// MARK: Get entries
extension ScheduleTestsProtocol {
    static func getEntries(
        divisions: [LeagueDivision.IDValue],
        gameDays: LeagueDayIndex,
        times: LeagueTimeIndex,
        locations: LeagueLocationIndex,
        teams: Int,
        homeLocations: ContiguousArray<BitSet64<LeagueLocationIndex>> = [],
        byes: ContiguousArray<Set<LeagueDayIndex>> = []
    ) -> [LeagueEntry.Runtime] {
        let playsOn = Array(repeating: Set(0..<gameDays), count: teams)
        let playsAtTimes = Array(repeating: Array(repeating: BitSet64(0..<times), count: gameDays), count: teams)
        let playsAtLocations = Array(repeating: Array(repeating: BitSet64(0..<locations), count: gameDays), count: teams)
        var entries = [LeagueEntry.Runtime]()
        entries.reserveCapacity(teams)
        for division in divisions {
            let entry = LeagueEntry.Runtime(
                id: LeagueEntry.IDValue(entries.count),
                division: division,
                gameDays: playsOn[entries.count],
                gameTimes: playsAtTimes[entries.count],
                gameLocations: playsAtLocations[entries.count],
                homeLocations: homeLocations[uncheckedPositive: entries.count] ?? .init(),
                byes: byes[uncheckedPositive: entries.count] ?? [],
                matchupsPerGameDay: nil
            )
            entries.append(entry)
        }
        return entries
    }
}

extension ScheduleTestsProtocol {
    static func getDivision(
        dayOfWeek: LeagueDayOfWeek,
        gameGaps: [GameGap] = [],
        values: (
            gameDays: LeagueDayIndex,
            entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
            entriesCount: Int
        )
    ) throws(LeagueError) -> LeagueDivision.Runtime {
        let maxSameOpponentMatchups = try LeagueRequestPayload.calculateMaximumSameOpponentMatchupsCap(
            gameDays: values.gameDays,
            entryMatchupsPerGameDay: values.entryMatchupsPerGameDay,
            entriesCount: values.entriesCount
        )
        return .init(
            dayOfWeek: dayOfWeek,
            gameDays: Set(0..<values.gameDays),
            gameGaps: gameGaps,
            maxSameOpponentMatchups: maxSameOpponentMatchups
        )
    }
}

// MARK: Get schedule
extension ScheduleTestsProtocol {
    static func getSchedule(
        gameDays: LeagueDayIndex,
        entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
        maximumPlayableMatchups: [UInt32] = [],
        entriesPerLocation: LeagueEntriesPerMatchup,
        matchupDuration: LeagueMatchupDuration = 0,
        startingTimes: [StaticTime],
        locations: LeagueLocationIndex,
        optimizeTimes: Bool,
        prioritizeEarlierTimes: Bool = true,
        prioritizeHomeAway: Bool,
        balanceHomeAway: Bool = true,
        sameLocationIfB2B: Bool = false,
        redistributionSettings: LitLeagues_Leagues_RedistributionSettings? = nil,
        balanceTimeStrictness: LeagueBalanceStrictness,
        balanceLocationStrictness: LeagueBalanceStrictness,
        gameGaps: GameGap,
        divisions: [LeagueDivision.Runtime],
        divisionsCanPlayOnSameDay: Bool = true,
        divisionsCanPlayAtSameTime: Bool = true,
        entries: [LeagueEntry.Runtime]
    ) -> some LeagueRequestPayload.RuntimeProtocol {
        let correctMaximumPlayableMatchups = LeagueRequestPayload.calculateMaximumPlayableMatchups(
            gameDays: gameDays,
            entryMatchupsPerGameDay: entryMatchupsPerGameDay,
            teamsCount: entries.count,
            maximumPlayableMatchups: maximumPlayableMatchups
        )
        let times:LeagueTimeIndex = LeagueTimeIndex(startingTimes.count)
        let timeSlots:Set<LeagueTimeIndex> = Set(0..<times)
        let matchupSlots:Set<LeagueLocationIndex> = Set(0..<locations)
        let generalSettings = LeagueGeneralSettings.Runtime.init(
            gameGap: gameGaps,
            timeSlots: LeagueTimeIndex(startingTimes.count),
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
            flags: LeagueSettingFlags.get(
                optimizeTimes: optimizeTimes,
                prioritizeEarlierTimes: prioritizeEarlierTimes,
                prioritizeHomeAway: prioritizeHomeAway,
                balanceHomeAway: balanceHomeAway,
                sameLocationIfB2B: sameLocationIfB2B
            )
        )
        
        var daySettings = [LeagueGeneralSettings.Runtime<Set<LeagueTimeIndex>, Set<LeagueLocationIndex>>]()
        daySettings.reserveCapacity(gameDays)
        for day in 0..<gameDays {
            var settings = generalSettings
            settings.computeSettings(day: day, entries: entries)
            daySettings.append(settings)
        }
        return LeagueRequestPayload.Runtime(
            gameDays: gameDays,
            divisions: divisions,
            entries: entries,
            general: generalSettings,
            daySettings: daySettings
        )
    }
}