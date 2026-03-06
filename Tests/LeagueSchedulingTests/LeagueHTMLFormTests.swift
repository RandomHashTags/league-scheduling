
@testable import LeagueScheduling
import Testing

@Suite
struct LeagueHTMLFormTests {
    @Test
    func leagueHTMLFormDefaultPayload() throws {
        let payload = payload()
        let _ = try payload.parseSettings()
    }
}

// MARK: Game days
extension LeagueHTMLFormTests {
    @Test
    func leagueHTMLFormGameDays() {
        var payload = payload()
        payload.gameDays = 0
        #expect(throws: LeagueError.malformedInput(msg: "'gameDays' needs to be > 0")) {
            try payload.parseSettings()
        }
    }
}

// MARK: Starts
extension LeagueHTMLFormTests {
    @Test
    func leagueHTMLFormStarts() {
        var payload = payload()
        payload.starts = "1/25/2024"
        #expect(throws: LeagueError.malformedHTMLDateInput(key: "starts", value: payload.starts ?? "")) {
            try payload.parseSettings()
        }
    }
}

// MARK: Entry game times
extension LeagueHTMLFormTests {
    @Test
    func leagueHTMLFormEntryGameTimes() throws {
        var payload = payload()
        for i in 0..<payload.entries.count {
            payload.entries[i].gameDays.gameDayIndexes = [0, 1, 2]
        }
        var settings = try payload.parseSettings()
        for team in 0..<payload.entries.count {
            for i in 0..<payload.gameDays {
                try #require(settings.entries[team].gameTimes[unchecked: i] == .init([0,1,2]))
            }
        }
        payload.entries[0].gameDayTimes.times[0].times = [0]
        settings = try payload.parseSettings()
        try #require(settings.entries[0].gameTimes[0] == .init([0]))
        try #require(settings.entries[0].gameTimes[1] == .init([0,1,2]))

        payload.entries[0].gameDayTimes.times[2].times = []
        settings = try payload.parseSettings()
        try #require(settings.entries[0].gameTimes[0] == .init([0]))
        try #require(settings.entries[0].gameTimes[2] == .init())
        try #require(settings.entries[0].gameTimes[3] == .init([0,1,2]))
    }
}

// MARK: Matchups per game day
extension LeagueHTMLFormTests {
    @Test
    func leagueHTMLFormMatchupsPerGameDay() throws {
        var payload = payload()
        let matchupsPerGameDay:[LeagueEntryMatchupsPerGameDay] = [2, 4, 2, 2, 3, 2, 2, 5]
        for i in 0..<payload.entries.count {
            payload.entries[i].matchupsPerGameDay = .init(gameDayMatchups: matchupsPerGameDay)
        }
        var settings = try payload.parseSettings()
        for team in 0..<payload.entries.count {
            try #require(settings.entries[team].matchupsPerGameDay?.gameDayMatchups == matchupsPerGameDay)
        }
    }
}


// MARK: Payload
extension LeagueHTMLFormTests {
    func payload() -> LeagueRequestPayload {
        let gameDays:LeagueDayIndex = 8
        let teamsCount = 9
        var teams = [LeagueEntry]()
        var gameTimes = LeagueGameTimes()
        gameTimes.times = [0, 1, 2]
        var gameLocations = LeagueGameLocations()
        gameLocations.locations = [0, 1, 2]
        for _ in 0..<teamsCount {
            teams.append(.init(
                division: 0,
                gameDays: .init(gameDayIndexes: [0, 1, 2, 3, 4, 5, 6, 7]),
                gameDayTimes: .init(times: .init(repeating: gameTimes, count: gameDays)),
                gameDayLocations: .init(locations: .init(repeating: gameLocations, count: gameDays)),
                homeLocations: nil,
                byes: nil
            ))
        }
        return LeagueRequestPayload.init(
            starts: "2024-01-25",
            //ends: "2024-03-14",
            gameDays: gameDays,
            settings: .init(
                gameGap: "upto 1",
                timeSlots: 3,
                startingTimes: [
                    .init(hour: 6, minute: 30),
                    .init(hour: 7, minute: 0),
                    .init(hour: 7, minute: 30)
                ],
                entriesPerLocation: 2,
                locations: 3,
                entryMatchupsPerGameDay: 2,
                maximumPlayableMatchups: .init(repeating: gameDays * 2, count: teams.count),
                balanceTimeStrictness: .normal,
                balancedTimes: [0, 1, 2],
                balanceLocationStrictness: .normal,
                balancedLocations: [0, 1, 2],
                flags: .max
            ),

            individualDaySettings: nil,

            divisions: [
                .init()
            ],
            teams: teams
        )
    }
}

// MARK: LeagueError equatable
extension LeagueError: Equatable {
    public static func == (lhs: LeagueError, rhs: LeagueError) -> Bool {
        switch lhs {
        case .malformedHTMLDateInput(let key, let value):
            guard case let .malformedHTMLDateInput(key2, value2) = rhs else { return false }
            return key == key2 && value == value2
        case .malformedInput(let msg):
            guard case let .malformedInput(msg2) = rhs else { return false }
            return msg == msg2
        case .failedNegativeDayIndex:
            return rhs == .failedNegativeDayIndex
        case .failedZeroExpectedMatchupsForDay(let dayIndex):
            guard case let .failedZeroExpectedMatchupsForDay(dayIndex2) = rhs else { return false }
            return dayIndex == dayIndex2
        case .failedRedistributionRequiresPreviouslyScheduledMatchups:
            return rhs == .failedRedistributionRequiresPreviouslyScheduledMatchups
        case .failedRedistributingMatchupsForDay(let dayIndex):
            guard case let .failedRedistributingMatchupsForDay(dayIndex2) = rhs else { return false }
            return dayIndex == dayIndex2
        case .failedAssignment(let balanceTimeStrictness):
            guard case let .failedAssignment(balanceTimeStrictness2) = rhs else { return false }
            return balanceTimeStrictness == balanceTimeStrictness2
        case .timedOut(let function):
            guard case let .timedOut(function2) = rhs else { return false }
            return function == function2
        }
    }
}