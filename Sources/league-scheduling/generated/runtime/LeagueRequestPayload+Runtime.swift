
#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
#elseif canImport(Foundation)
import struct Foundation.Date
#endif

import SwiftProtobuf

// MARK: Runtime
extension LeagueRequestPayload {
    protocol RuntimeProtocol: Sendable, ~Copyable {
        associatedtype ConcreteGeneralSettings:LeagueGeneralSettings.RuntimeProtocol

        /// Number of days where games are played.
        var gameDays: LeagueDayIndex { get }

        /// Divisions associated with this schedule.
        var divisions: [LeagueDivision.Runtime] { get }

        /// Entries that participate in this schedule.
        var entries: [LeagueEntry.Runtime] { get }

        /// General settings for this schedule.
        var general: ConcreteGeneralSettings { get }

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        var daySettings: [ConcreteGeneralSettings] { get }
    }

    /// For optimal runtime performance.
    struct Runtime<T: LeagueGeneralSettings.RuntimeProtocol>: RuntimeProtocol {
        /// Number of days where games are played.
        let gameDays:LeagueDayIndex

        /// Divisions associated with this schedule.
        let divisions:[LeagueDivision.Runtime]

        /// Entries that participate in this schedule.
        let entries:[LeagueEntry.Runtime]

        /// General settings for this schedule.
        let general:T

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`LeagueDayIndex`: `LeagueDaySettings`]
        let daySettings:[T]

        init(
            gameDays: LeagueDayIndex,
            divisions: [LeagueDivision.Runtime],
            entries: [LeagueEntry.Runtime],
            general: T,
            daySettings: [T]
        ) {
            self.gameDays = gameDays
            self.divisions = divisions
            self.entries = entries
            self.general = general
            self.daySettings = daySettings
        }
    }
}