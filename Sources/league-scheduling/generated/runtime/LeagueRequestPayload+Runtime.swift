
#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
#elseif canImport(Foundation)
import struct Foundation.Date
#endif

import SwiftProtobuf

// MARK: Runtime
extension LeagueRequestPayload {
    /// For optimal runtime performance.
    public struct Runtime: Codable, Sendable {
        let constraints:GenerationConstraints

        /// Number of days where games are played.
        public let gameDays:LeagueDayIndex

        /// Divisions associated with this schedule.
        public let divisions:[LeagueDivision.Runtime]

        /// Entries that participate in this schedule.
        public let entries:[LeagueEntry.Runtime]

        /// General settings for this schedule.
        public let general:LeagueGeneralSettings.Runtime

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        public let daySettings:[LeagueDaySettings.Runtime]

        public init(
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