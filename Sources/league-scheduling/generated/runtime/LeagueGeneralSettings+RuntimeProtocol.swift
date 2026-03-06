
import StaticDateTimes

extension LeagueGeneralSettings {
    protocol RuntimeProtocol: Sendable, ~Copyable {
        associatedtype Times:SetOfTimeIndexes
        associatedtype Locations:SetOfLocationIndexes

        var gameGap: GameGap { get set }
        var timeSlots: LeagueTimeIndex { get set }

        var startingTimes: [StaticTime] { get set }
        var entriesPerLocation: LeagueEntriesPerMatchup { get set }
        var locations: LeagueLocationIndex { get set }
        var defaultMaxEntryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay { get set }
        var maximumPlayableMatchups: [UInt32] { get set }
        var matchupDuration: LeagueMatchupDuration { get set }
        var locationTimeExclusivities: [Times]? { get set }
        var locationTravelDurations: [[LeagueMatchupDuration]]? { get set }
        var balanceTimeStrictness: LeagueBalanceStrictness { get set }
        var balancedTimes: Times { get set }
        var balanceLocationStrictness: LeagueBalanceStrictness { get set }
        var balancedLocations: Locations { get set }
        var redistributionSettings: LitLeagues_Leagues_RedistributionSettings? { get set }
        var flags: UInt32 { get set }

        init(protobuf: LeagueGeneralSettings) throws(LeagueError)
        init(gameGap: GameGap, protobuf: LeagueGeneralSettings)
        init(
            gameGap: GameGap,
            timeSlots: LeagueTimeIndex,
            startingTimes: [StaticTime],
            entriesPerLocation: LeagueEntriesPerMatchup,
            locations: LeagueLocationIndex,
            entryMatchupsPerGameDay: LeagueEntryMatchupsPerGameDay,
            maximumPlayableMatchups: [UInt32],
            matchupDuration: LeagueMatchupDuration,
            locationTimeExclusivities: [Times]?,
            locationTravelDurations: [[LeagueMatchupDuration]]?,
            balanceTimeStrictness: LeagueBalanceStrictness,
            balancedTimes: Times,
            balanceLocationStrictness: LeagueBalanceStrictness,
            balancedLocations: Locations,
            redistributionSettings: LitLeagues_Leagues_RedistributionSettings?,
            flags: UInt32
        )

        mutating func apply(
            gameDays: LeagueDayIndex,
            entriesCount: Int,
            correctMaximumPlayableMatchups: [UInt32],
            general: borrowing Self,
            customDaySettings: LeagueGeneralSettings
        )

        func availableSlots() -> Set<LeagueAvailableSlot>
    }
}

// MARK: Flags
extension LeagueGeneralSettings.RuntimeProtocol {
    func isFlag(_ flag: LeagueSettingFlags) -> Bool {
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
extension LeagueGeneralSettings.RuntimeProtocol {
    init(
        protobuf: LeagueGeneralSettings
    ) throws(LeagueError) {
        guard let gameGap = GameGap(htmlInputValue: protobuf.gameGap) else {
            throw .malformedInput(msg: "invalid GameGap htmlInputValue: \(protobuf.gameGap)")
        }
        self.init(gameGap: gameGap, protobuf: protobuf)
    }

    /// Modifies `timeSlots` and `startingTimes` taking into account current settings.
    mutating func computeSettings(
        day: LeagueDayIndex,
        entries: [LeagueEntry.Runtime]
    ) {
        if optimizeTimes {
            var maxMatchupsPlayedToday:LeagueLocationIndex = 0
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