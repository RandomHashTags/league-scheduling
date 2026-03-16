
import StaticDateTimes

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