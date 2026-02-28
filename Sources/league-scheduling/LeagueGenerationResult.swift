
#if canImport(FoundationEssentials)
import struct FoundationEssentials.UUID
#elseif canImport(Foundation)
import struct Foundation.UUID
#endif

public struct LeagueGenerationResult: Sendable {
    public let id:UUID
    public let results:[LeagueGenerationData]
    public let error:String?
    public let settings:LeagueRequestPayload.Runtime

    public init(
        id: UUID,
        results: [LeagueGenerationData],
        error: String?,
        settings: LeagueRequestPayload.Runtime
    ) {
        self.id = id
        self.results = results
        self.error = error
        self.settings = settings
    }
}

// MARK: Codable
extension LeagueGenerationResult: Codable {
}