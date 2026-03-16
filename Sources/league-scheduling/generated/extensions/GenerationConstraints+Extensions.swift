
// MARK: Init
extension GenerationConstraints {
    init(
        timeoutDelay: UInt32,
        regenerationAttemptsForFirstDay: UInt32,
        regenerationAttemptsForConsecutiveDay: UInt32,
        regenerationAttemptsThreshold: UInt32
    ) {
        self.timeoutDelay = timeoutDelay
        self.regenerationAttemptsForFirstDay = regenerationAttemptsForFirstDay
        self.regenerationAttemptsForConsecutiveDay = regenerationAttemptsForConsecutiveDay
        self.regenerationAttemptsThreshold = regenerationAttemptsThreshold
    }
}

// MARK: Default
extension GenerationConstraints {
    static let `default` = Self(
        timeoutDelay: 60,
        regenerationAttemptsForFirstDay: 100,
        regenerationAttemptsForConsecutiveDay: 100,
        regenerationAttemptsThreshold: 10_000
    )
}