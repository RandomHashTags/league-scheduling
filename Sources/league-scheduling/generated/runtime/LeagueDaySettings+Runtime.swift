
extension LeagueDaySettings {
    func runtime() throws(LeagueError) -> Runtime {
        try .init(protobuf: self)
    }

    /// For optimal runtime performance.
    struct Runtime: Sendable {
        let general:LeagueGeneralSettings.Runtime

        init(protobuf: LeagueDaySettings) throws(LeagueError) {
            general = try protobuf.settings.runtime()
        }

        init(
            general: LeagueGeneralSettings.Runtime
        ) {
            self.general = general
        }
    }
}