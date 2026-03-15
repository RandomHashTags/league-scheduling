
extension DaySettings {
    func runtime() throws(LeagueError) -> Runtime {
        try .init(protobuf: self)
    }

    /// For optimal runtime performance.
    struct Runtime: Sendable {
        let general:GeneralSettings.Runtime

        init(protobuf: DaySettings) throws(LeagueError) {
            general = try protobuf.settings.runtime()
        }

        init(
            general: GeneralSettings.Runtime
        ) {
            self.general = general
        }
    }
}