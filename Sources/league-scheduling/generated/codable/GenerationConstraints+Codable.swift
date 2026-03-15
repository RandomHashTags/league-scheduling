
#if ProtobufCodable
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
#endif