
import Foundation

/// Record the time taken to execute something.
public struct ExecutionStep: Sendable {
    public let key:String
    public let nanoseconds:String

    public init(key: String, duration: Duration) {
        self.key = key
        let totalNano = UInt64(duration.components.seconds * 1_000_000_000) + UInt64(duration.components.attoseconds / 1_000_000_000)
        nanoseconds = ExecutionStep.numberFormatter.string(from: NSNumber(value: totalNano)) ?? "\(totalNano)"
    }
    public init(key: String, nanoseconds: String) {
        self.key = key
        self.nanoseconds = nanoseconds
    }

    static let numberFormatter:NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter
    }()
}

// MARK: Codable
extension ExecutionStep: Codable {
}