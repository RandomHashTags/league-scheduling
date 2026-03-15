
import StaticDateTimes

struct CanPlayAtGameGap: Sendable, ~Copyable {
    /// - Returns: If a team with the provided `playsAtTimes` can play at the given `time` taking into account a `gameGap`.
    static func test(
        time: TimeIndex,
        playsAtTimes: PlaysAtTimes.Element,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        var closest:TimeIndex? = nil
        for playedTime in playsAtTimes {
            let distance = abs(playedTime.distance(to: time))
            if closest == nil || distance < closest! {
                closest = TimeIndex(distance)
            }
        }
        if let distance = closest {
            return gameGapIsAllowed(distance: distance, gameGap: gameGap)
        }
        return true
    }

    /// - Returns: If a game gap allows a matchup to be played given the absolute distance from the closest played time to a schedule time.
    static func gameGapIsAllowed(
        distance: TimeIndex,
        gameGap: GameGap.TupleValue
    ) -> Bool {
        return distance >= gameGap.min && distance <= gameGap.max
    }
}