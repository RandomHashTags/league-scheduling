
extension LitLeagues_Leagues_RedistributionSettings {
    init(
        minMatchupsRequired: UInt32? = nil,
        maxMovableMatchups: UInt32? = nil
    ) {
        if let v = minMatchupsRequired {
            self.minMatchupsRequired = v
        }
        if let v = maxMovableMatchups {
            self.maxMovableMatchups = v
        }
    }
}