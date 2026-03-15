
extension LitLeagues_Leagues_RedistributionSettings {
    init(
        minMatchupsRequired: UInt32? = nil,
        maxMovableMatchups: UInt32? = nil
    ) {
        if let m = minMatchupsRequired {
            self.minMatchupsRequired = m
        }
        if let m = maxMovableMatchups {
            self.maxMovableMatchups = m
        }
    }
}