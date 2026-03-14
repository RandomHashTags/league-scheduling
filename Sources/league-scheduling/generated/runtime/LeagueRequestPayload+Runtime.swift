
#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
#elseif canImport(Foundation)
import struct Foundation.Date
#endif

import SwiftProtobuf

// MARK: Runtime
extension LeagueRequestPayload {
    /// For optimal runtime performance.
    struct Runtime: Sendable {
        let constraints:GenerationConstraints

        /// Number of days where games are played.
        let gameDays:LeagueDayIndex

        /// Divisions associated with this schedule.
        let divisions:[LeagueDivision.Runtime]

        /// Entries that participate in this schedule.
        let entries:[LeagueEntry.Runtime]

        /// General settings for this schedule.
        let general:LeagueGeneralSettings.Runtime

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        let daySettings:[LeagueDaySettings.Runtime]

        init(
            constraints: GenerationConstraints,
            gameDays: LeagueDayIndex,
            divisions: [LeagueDivision.Runtime],
            entries: [LeagueEntry.Runtime],
            general: LeagueGeneralSettings.Runtime,
            daySettings: [LeagueDaySettings.Runtime]
        ) {
            self.constraints = constraints
            self.gameDays = gameDays
            self.divisions = divisions
            self.entries = entries
            self.general = general
            self.daySettings = daySettings
        }
    }
}