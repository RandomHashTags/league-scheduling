
extension LeagueDaySettings {
    public func runtime() throws(LeagueError) -> Runtime {
        try .init(protobuf: self)
    }

    /// For optimal runtime performance.
    public struct Runtime: Codable, Sendable {
        public let general:LeagueGeneralSettings.Runtime

        public init(protobuf: LeagueDaySettings) throws(LeagueError) {
            general = try protobuf.settings.runtime()
        }

        public init(
            general: LeagueGeneralSettings.Runtime
        ) {
            self.general = general
        }
    }
}