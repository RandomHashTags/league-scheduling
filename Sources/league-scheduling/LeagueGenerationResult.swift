
public struct LeagueGenerationResult: Sendable {
    public let results:[LeagueGenerationData]
    public let error:String?
}

#if ProtobufCodable
extension LeagueGenerationResult: Codable {
}
#endif