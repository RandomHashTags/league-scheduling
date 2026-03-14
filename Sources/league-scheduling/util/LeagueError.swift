
public enum LeagueError: CustomStringConvertible, Error, Sendable {
    case malformedHTMLDateInput(key: String, value: String)
    case malformedInput(msg: String? = nil)

    case failedNegativeDayIndex
    case failedZeroExpectedMatchupsForDay(LeagueDayIndex)
    case failedRedistributionRequiresPreviouslyScheduledMatchups
    case failedRedistributingMatchupsForDay(LeagueDayIndex)
    case failedAssignment(regenerationAttemptsThreshold: UInt32, balanceTimeStrictness: LeagueBalanceStrictness)

    case timedOut(function: String)

    public var description: String {
        switch self {
        case .malformedHTMLDateInput(let key, let value):
            return "Malformed \"\(key)\" htmlDate value: \"\(value)\""
        case .malformedInput(let msg):
            var s = "Malformed input"
            if let msg {
                s += ": \(msg)"
            }
            return s
        case .failedNegativeDayIndex:
            return "Failed trying to generate schedule on a negative day_index; try regenerating"
        case .failedZeroExpectedMatchupsForDay(let dayIndex):
            return "Failed trying to generate schedule on dayIndex \(dayIndex) due to zero matchups being scheduled for day; something is misconfigured"

        case .failedRedistributionRequiresPreviouslyScheduledMatchups:
            return "Failed trying to redistribute matchups due to having none previously scheduled"
        case .failedRedistributingMatchupsForDay(let dayIndex):
            return "Failed trying to redistribute matchups for dayIndex \(dayIndex); something is misconfigured"

        case .failedAssignment(let regenerationAttemptsThreshold, let balanceTimeStrictness):
            var string = "Failed location/time assignment in \(regenerationAttemptsThreshold) attempts; something may be misconfigured; try regenerating"
            if balanceTimeStrictness != .relaxed {
                string += " or using 'relaxed' time strictness"
            }
            return string

        case .timedOut(let function):
            return "Failed to build schedule within provided time limit; try regenerating (timed out; function=" + function + ")"
        }
    }
}
