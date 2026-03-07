
#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
#elseif canImport(Foundation)
import struct Foundation.Date
#endif

import SwiftProtobuf

// MARK: Runtime
extension LeagueRequestPayload {
    /// For optimal runtime performance.
    struct Runtime<Config: ScheduleConfiguration>: Sendable {
        /// Number of days where games are played.
        let gameDays:LeagueDayIndex

        /// Divisions associated with this schedule.
        let divisions:[LeagueDivision.Runtime]

        /// Entries that participate in this schedule.
        let entries:[Config.EntryRuntime]

        /// General settings for this schedule.
        let general:LeagueGeneralSettings.Runtime<Config>

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        let daySettings:[LeagueGeneralSettings.Runtime<Config>]

        init(
            gameDays: LeagueDayIndex,
            divisions: [LeagueDivision.Runtime],
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
    }
}