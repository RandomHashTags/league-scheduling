
extension LeagueDaySettings {
    /// For optimal runtime performance.
    public struct Runtime: Codable, Sendable {
        public let general:LeagueGeneralSettings.Runtime

        public init(protobuf: LeagueDaySettings) throws(LeagueError) {
            general = try .init(protobuf: protobuf.settings)
        }

        public init(
            general: LeagueGeneralSettings.Runtime
        ) {
            self.general = general
        }
    }
}