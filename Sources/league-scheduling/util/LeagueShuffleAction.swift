
public struct LeagueShuffleAction: Sendable {
    public let day:UInt32
    public let from:LitLeagues_Leagues_AvailableSlot
    public let to:LitLeagues_Leagues_AvailableSlot
    public let pair:LitLeagues_Leagues_MatchupPair
}

#if ProtobufCodable
// MARK: Codable
extension LeagueShuffleAction: Codable {
}
#endif