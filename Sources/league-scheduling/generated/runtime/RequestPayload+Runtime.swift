
extension RequestPayload {
    /// For optimal runtime performance.
    struct Runtime<Config: ScheduleConfiguration>: Sendable, ~Copyable {
        let constraints:GenerationConstraints

        /// Number of days where games are played.
        let gameDays:DayIndex

        /// Divisions associated with this schedule.
        let divisions:[Config.DivisionRuntime]

        /// Entries that participate in this schedule.
        let entries:[Config.EntryRuntime]

        /// General settings for this schedule.
        let general:GeneralSettings.Runtime<Config>

        /// Individual settings for the given day index.
        /// 
        /// - Usage: [`DayIndex`: `DaySettings`]
        let daySettings:[GeneralSettings.Runtime<Config>]

        #if SpecializeScheduleConfiguration
        @_specialize(where Config == ScheduleConfig<BitSet64<DayIndex>, BitSet64<TimeIndex>, BitSet64<LocationIndex>, BitSet64<Entry.IDValue>>)
        @_specialize(where Config == ScheduleConfig<Set<DayIndex>, Set<TimeIndex>, Set<LocationIndex>, Set<Entry.IDValue>>)
        #endif
        init(
            constraints: GenerationConstraints,
            gameDays: DayIndex,
            divisions: [Config.DivisionRuntime],
            entries: [Config.EntryRuntime],
            general: GeneralSettings.Runtime<Config>,
            daySettings: [GeneralSettings.Runtime<Config>]
        ) {
            self.constraints = constraints
            self.gameDays = gameDays
            self.divisions = divisions
            self.entries = entries
            self.general = general
            self.daySettings = daySettings
        }

        func copy() -> Self {
            .init(constraints: constraints, gameDays: gameDays, divisions: divisions, entries: entries, general: general, daySettings: daySettings)
        }

        func redistributionSettings(for day: DayIndex) -> LitLeagues_Leagues_RedistributionSettings? {
            daySettings[unchecked: day].redistributionSettings ?? general.redistributionSettings
        }
    }
}