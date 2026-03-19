
extension LitLeagues_Leagues_Determinism {
    init(
        technique: UInt32? = nil,
        seed: UInt64? = nil
    ) {
        if let technique {
            self.technique = technique
        }
        if let seed {
            self.seed = seed
        }
    }
}