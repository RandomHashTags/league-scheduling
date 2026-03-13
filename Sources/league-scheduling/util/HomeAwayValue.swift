
struct HomeAwayValue: Sendable {
    /// Number of matchups played at 'home'.
    var home:UInt8

    /// Number of matchups played at 'away'.
    var away:UInt8

    var sum: UInt16 {
        UInt16(home) + UInt16(away)
    }
}