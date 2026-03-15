
extension RequestPayload {
    /// For optimal runtime performance.
    struct Runtime: Sendable {
        let constraints:GenerationConstraints

        /// Number of days where games are played.
        let gameDays:DayIndex

        /// Divisions associated with this schedule.
        let divisions:[Division.Runtime]

        /// Entries that participate in this schedule.
        let entries:[Entry.Runtime]

        /// General settings for this schedule.
        let general:GeneralSettings.Runtime

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`DayIndex`: `DaySettings`]
        let daySettings:[DaySettings.Runtime]
    }
}