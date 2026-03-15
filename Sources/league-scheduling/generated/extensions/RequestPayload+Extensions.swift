
// MARK: Init
extension LeagueRequestPayload {
    init(
        starts: String? = nil,
        gameDays: LeagueDayIndex,

        settings: LeagueGeneralSettings,
        individualDaySettings: LitLeagues_Leagues_DaySettingsArray?,

        divisions: [LeagueDivision],
        teams: [LeagueEntry]
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
extension LeagueRequestPayload {
    public func generate() async throws(LeagueError) -> LeagueGenerationResult {
        let settings = try parseSettings()
        return await LeagueSchedule.init(settings: settings).generate()
    }
}