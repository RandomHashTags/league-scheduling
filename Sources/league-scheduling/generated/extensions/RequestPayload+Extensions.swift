
// MARK: Init
extension RequestPayload {
    init(
        starts: String? = nil,
        gameDays: DayIndex,

        settings: GeneralSettings,
        individualDaySettings: LitLeagues_Leagues_DaySettingsArray?,

        divisions: [Division],
        teams: [Entry]
    ) {
        if let starts {
            self.starts = starts
        }

        self.gameDays = gameDays

        self.settings = settings
        if let individualDaySettings {
            self.individualDaySettings = individualDaySettings
        }

        self.divisions = .init(divisions: divisions)
        self.entries = teams
    }
}

// MARK: Calculate max playable matchups
extension RequestPayload {
    static func calculateMaximumPlayableMatchups(
        gameDays: DayIndex,
        entryMatchupsPerGameDay: EntryMatchupsPerGameDay,
        teamsCount: Int,
        maximumPlayableMatchups: [UInt32]
    ) -> [UInt32] {
        if maximumPlayableMatchups.isEmpty {
            return .init(repeating: gameDays * entryMatchupsPerGameDay, count: teamsCount)
        } else if maximumPlayableMatchups.count != teamsCount {
            var array = [UInt32](repeating: gameDays * entryMatchupsPerGameDay, count: teamsCount)
            for i in 0..<min(teamsCount, maximumPlayableMatchups.count) {
                array[i] = maximumPlayableMatchups[i]
            }
            return array
        } else {
            return maximumPlayableMatchups
        }
    }
}