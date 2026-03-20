
/// A scheduled `Matchup` that can be moved from its current day and slot to another.
/// 
/// Only used when redistributing matchups.
struct RedistributableMatchup: Hashable, Sendable {
    let fromDay:DayIndex
    var matchup:Matchup
    let toSlot:AvailableSlot
}