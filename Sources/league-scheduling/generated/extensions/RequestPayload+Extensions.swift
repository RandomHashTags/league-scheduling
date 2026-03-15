
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

// MARK: Generate
extension RequestPayload {
    public func generate() async throws(LeagueError) -> LeagueGenerationResult {
        let settings = try parseSettings()
        return await LeagueSchedule.init(settings: settings).generate()
    }
}