
public struct LeagueGenerationResult: Sendable {
    public let results:[LeagueGenerationData]
    public let error:String?

    init(
        results: [LeagueGenerationData],
        error: String?
    ) {
        self.results = results
        self.error = error
    }
}