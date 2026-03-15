
#if ProtobufCodable
extension LitLeagues_Leagues_DivisionOpponents: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        divisionOpponentIds = try container.decode([LeagueDivision.IDValue].self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(divisionOpponentIds)
    }
}
#endif