
/// A scheduled `Matchup` where the home and away teams can be swapped.
/// 
/// Only used when balancing the final scheduled matchup's home/away.
struct FlippableMatchup: Hashable, Sendable {
    let day:DayIndex
    var matchup:Matchup
}