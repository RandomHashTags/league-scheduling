
// MARK: Init
extension GenerationConstraints {
    init(
        timeoutDelay: UInt32,
        regenerationAttemptsForFirstDay: UInt32,
        regenerationAttemptsForConsecutiveDay: UInt32,
        regenerationAttemptsThreshold: UInt32,
        determinism: LitLeagues_Leagues_Determinism?,
        attempts: UInt32
    ) {
        self.timeoutDelay = timeoutDelay
        self.regenerationAttemptsForFirstDay = regenerationAttemptsForFirstDay
        self.regenerationAttemptsForConsecutiveDay = regenerationAttemptsForConsecutiveDay
        self.regenerationAttemptsThreshold = regenerationAttemptsThreshold
        if let determinism {
            self.determinism = determinism
        }
        self.attempts = attempts
    }
}

// MARK: Default
extension GenerationConstraints {
    static let `default` = Self(
        timeoutDelay: 60,
        regenerationAttemptsForFirstDay: 100,
        regenerationAttemptsForConsecutiveDay: 100,
        regenerationAttemptsThreshold: 10_000,
        determinism: nil,
        attempts: 1
    )
}