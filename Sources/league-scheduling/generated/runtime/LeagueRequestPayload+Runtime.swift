
#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
#elseif canImport(Foundation)
import struct Foundation.Date
#endif

import SwiftProtobuf

// MARK: Runtime
extension LeagueRequestPayload {
    /// For optimal runtime performance.
    struct Runtime<Config: ScheduleConfiguration>: Sendable, ~Copyable {
        /// Number of days where games are played.
        let gameDays:LeagueDayIndex

        /// Divisions associated with this schedule.
        let divisions:[Config.DivisionRuntime]

        /// Entries that participate in this schedule.
        let entries:[Config.EntryRuntime]

        /// General settings for this schedule.
        let general:LeagueGeneralSettings.Runtime<Config>

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        let daySettings:[LeagueGeneralSettings.Runtime<Config>]

        #if SpecializeScheduleConfiguration
        @_specialize(where Config == ScheduleConfig<BitSet64<LeagueDayIndex>, BitSet64<LeagueTimeIndex>, BitSet64<LeagueLocationIndex>, BitSet64<LeagueEntry.IDValue>>)
        @_specialize(where Config == ScheduleConfig<Set<LeagueDayIndex>, Set<LeagueTimeIndex>, Set<LeagueLocationIndex>, Set<LeagueEntry.IDValue>>)
        #endif
        init(
            gameDays: LeagueDayIndex,
            divisions: [Config.DivisionRuntime],
            entries: [Config.EntryRuntime],
            general: LeagueGeneralSettings.Runtime<Config>,
            daySettings: [LeagueGeneralSettings.Runtime<Config>]
        ) {
            self.gameDays = gameDays
            self.divisions = divisions
            self.entries = entries
            self.general = general
            self.daySettings = daySettings
        }

        func copy() -> Self {
            .init(gameDays: gameDays, divisions: divisions, entries: entries, general: general, daySettings: daySettings)
        }

        func redistributionSettings(for day: LeagueDayIndex) -> LitLeagues_Leagues_RedistributionSettings? {
            daySettings[unchecked: day].redistributionSettings ?? general.redistributionSettings
        }
    }
}