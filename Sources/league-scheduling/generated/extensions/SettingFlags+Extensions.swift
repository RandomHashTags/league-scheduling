
extension SettingFlags {
    static func get(
        optimizeTimes: Bool,
        prioritizeEarlierTimes: Bool,
        prioritizeHomeAway: Bool,
        balanceHomeAway: Bool,
        sameLocationIfB2B: Bool
    ) -> UInt32 {
        var value:UInt32 = optimizeTimes ? 1 << Self.optimizeTimes.rawValue : 0
        value |= prioritizeEarlierTimes  ? 1 << Self.prioritizeEarlierTimes.rawValue : 0
        value |= prioritizeHomeAway      ? 1 << Self.prioritizeHomeAway.rawValue : 0
        value |= balanceHomeAway         ? 1 << Self.balanceHomeAway.rawValue : 0
        value |= sameLocationIfB2B       ? 1 << Self.sameLocationIfBackToBack.rawValue : 0
        return value
    }
}