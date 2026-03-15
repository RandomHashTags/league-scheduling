
extension LeagueDivision {
    func runtime(
        defaultGameDays: Set<LeagueDayIndex>,
        defaultGameGap: GameGap,
        fallbackDayOfWeek: LeagueDayOfWeek,
        fallbackMaxSameOpponentMatchups: LeagueMaximumSameOpponentMatchupsCap
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
        let dayOfWeek:LeagueDayOfWeek
        let gameDays:Set<LeagueDayIndex>
        let gameGaps:[GameGap]
        let maxSameOpponentMatchups:LeagueMaximumSameOpponentMatchupsCap

        init(
            protobuf: LeagueDivision,
            defaultGameDays: Set<LeagueDayIndex>,
            defaultGameGap: GameGap,
            fallbackDayOfWeek: LeagueDayOfWeek,
            fallbackMaxSameOpponentMatchups: LeagueMaximumSameOpponentMatchupsCap
        ) throws(LeagueError) {
            dayOfWeek = protobuf.hasDayOfWeek ? LeagueDayOfWeek(protobuf.dayOfWeek) : fallbackDayOfWeek
            self.gameDays = protobuf.hasGameDays ? Set(protobuf.gameDays.gameDayIndexes) : defaultGameDays
            gameGaps = protobuf.hasGameGaps ? try Self.parseGameGaps(protobuf.gameGaps.gameGaps) : .init(repeating: defaultGameGap, count: defaultGameDays.count)
            maxSameOpponentMatchups = protobuf.hasMaxSameOpponentMatchups ? protobuf.maxSameOpponentMatchups : fallbackMaxSameOpponentMatchups
        }

        init(
            dayOfWeek: LeagueDayOfWeek,
            gameDays: Set<LeagueDayIndex>,
            gameGaps: [GameGap],
            maxSameOpponentMatchups: LeagueMaximumSameOpponentMatchupsCap
        ) {
            self.dayOfWeek = dayOfWeek
            self.gameDays = gameDays
            self.gameGaps = gameGaps
            self.maxSameOpponentMatchups = maxSameOpponentMatchups
        }
    }
}

// MARK: Parse game gaps
extension LeagueDivision.Runtime {
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