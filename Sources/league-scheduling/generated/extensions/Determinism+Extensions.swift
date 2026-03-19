
extension LitLeagues_Leagues_Determinism {
    init(
        technique: UInt32? = nil,
        seed: UInt64? = nil,
        multiplier: UInt64? = nil,
        increment: UInt64? = nil
    ) {
        if let technique {
            self.technique = technique
        }
        if let seed {
            self.seed = seed
        }
        if let multiplier {
            self.multiplier = multiplier
        }
        if let increment {
            self.increment = increment
        }
    }
}