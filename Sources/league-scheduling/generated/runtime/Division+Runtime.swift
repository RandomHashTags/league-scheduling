
extension Division {
    func runtime(
        defaultGameDays: Set<DayIndex>,
        defaultGameGap: GameGap,
        fallbackDayOfWeek: DayOfWeek,
        fallbackMaxSameOpponentMatchups: MaximumSameOpponentMatchupsCap
    ) throws(LeagueError) -> Runtime {
        try .init(
            protobuf: self,
            defaultGameDays: defaultGameDays,
            defaultGameGap: defaultGameGap,
            fallbackDayOfWeek: fallbackDayOfWeek,
            fallbackMaxSameOpponentMatchups: fallbackMaxSameOpponentMatchups
        )
    }

    /// For optimal runtime performance.
    struct Runtime: Sendable {
        let dayOfWeek:DayOfWeek
        let gameDays:Set<DayIndex>
        let gameGaps:[GameGap]
        let maxSameOpponentMatchups:MaximumSameOpponentMatchupsCap

        init(
            protobuf: Division,
            defaultGameDays: Set<DayIndex>,
            defaultGameGap: GameGap,
            fallbackDayOfWeek: DayOfWeek,
            fallbackMaxSameOpponentMatchups: MaximumSameOpponentMatchupsCap
        ) throws(LeagueError) {
            dayOfWeek = protobuf.hasDayOfWeek ? DayOfWeek(protobuf.dayOfWeek) : fallbackDayOfWeek
            self.gameDays = protobuf.hasGameDays ? Set(protobuf.gameDays.gameDayIndexes) : defaultGameDays
            gameGaps = protobuf.hasGameGaps ? try Self.parseGameGaps(protobuf.gameGaps.gameGaps) : .init(repeating: defaultGameGap, count: defaultGameDays.count)
            maxSameOpponentMatchups = protobuf.hasMaxSameOpponentMatchups ? protobuf.maxSameOpponentMatchups : fallbackMaxSameOpponentMatchups
        }

        init(
            dayOfWeek: DayOfWeek,
            gameDays: Set<DayIndex>,
            gameGaps: [GameGap],
            maxSameOpponentMatchups: MaximumSameOpponentMatchupsCap
        ) {
            self.dayOfWeek = dayOfWeek
            self.gameDays = gameDays
            self.gameGaps = gameGaps
            self.maxSameOpponentMatchups = maxSameOpponentMatchups
        }
    }
}

// MARK: Parse game gaps
extension Division.Runtime {
    private static func parseGameGaps(_ gameGaps: [String]) throws(LeagueError) -> [GameGap] {
        var gaps = [GameGap]()
        gaps.reserveCapacity(gameGaps.count)
        for string in gameGaps {
            guard let gg = GameGap(htmlInputValue: string) else {
                throw LeagueError.malformedInput(msg: "invalid GameGap htmlInputValue: \(string)")
            }
            gaps.append(gg)
        }
        return gaps
    }
}