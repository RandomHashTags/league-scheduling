
import SwiftProtobuf

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
    }
}