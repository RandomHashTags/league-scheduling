
// MARK: Codable
extension GenerationConstraints: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .timeoutDelay) {
            timeoutDelay = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .regenerationAttemptsForFirstDay) {
            regenerationAttemptsForFirstDay = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .regenerationAttemptsForConsecutiveDay) {
            regenerationAttemptsForConsecutiveDay = v
        }
        if let v = try container.decodeIfPresent(UInt32.self, forKey: .regenerationAttemptsThreshold) {
            regenerationAttemptsThreshold = v
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if hasTimeoutDelay {
            try container.encode(timeoutDelay, forKey: .timeoutDelay)
        }
        if hasRegenerationAttemptsForFirstDay {
            try container.encode(regenerationAttemptsForFirstDay, forKey: .regenerationAttemptsForFirstDay)
        }
        if hasRegenerationAttemptsForConsecutiveDay {
            try container.encode(regenerationAttemptsForConsecutiveDay, forKey: .regenerationAttemptsForConsecutiveDay)
        }
        if hasRegenerationAttemptsThreshold {
            try container.encode(regenerationAttemptsThreshold, forKey: .regenerationAttemptsThreshold)
        }
    }

    enum CodingKeys: CodingKey {
        case timeoutDelay
        case regenerationAttemptsForFirstDay
        case regenerationAttemptsForConsecutiveDay
        case regenerationAttemptsThreshold
    }
}

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