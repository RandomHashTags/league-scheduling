
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct ScheduleBeanBagToss: ScheduleTestsProtocol {
    // MARK: 8GD | 3T | 3L | 1D | 9T
    @Test(.timeLimit(.minutes(1)))
    func schedule8GameDays3Times3Locations1Division9Teams() async throws {
        let schedule = try Self.schedule8GameDays3Times3Locations1Division9Teams()
        let data = await schedule.generate()
        try expectations(
            settings: schedule,
            matchupsCount: 72,
            data: data
        )
    }
    static func schedule8GameDays3Times3Locations1Division9Teams(
        constraints: GenerationConstraints = .default
    ) throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (8, 3, 3, 9)
        let entries = getEntries(
            divisions: [Division.IDValue](repeating: 0, count: teams),
            gameDays: gameDays,
            times: times,
            locations: locations,
            teams: teams
        )
        return getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: 2,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 6, minute: 30),
                StaticTime(hour: 7, minute: 0),
                StaticTime(hour: 7, minute: 30)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: entries,
            constraints: constraints
        )
    }
}

extension ScheduleBeanBagToss {
    // MARK: 11GD | 4T | 6L | 2D | 12x12T
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_11GameDays4Times6Locations2Divisions24Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (11, 4, 6, 24)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 12))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 12))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 264, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 5GD | 3T | 6L | 1D | 13T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjUwNTE2OA==&arg3=MzM0NjM=
    @Test(.timeLimit(.minutes(1)))
    func schedule5GameDays3Times6Locations1Division13Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (5, 3, 6, 13)
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: Self.getEntries(
                divisions: .init(repeating: 0, count: teams),
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 65, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 5GD | 2D | 9x16T
    // https://secure.rec1.com/MN/owatonna-mn/leagues/publicLeague/2505159
    @Test(.timeLimit(.minutes(1)))
    func schedule5GameDays4Times8Locations2Divisions25Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (5, 4, 8, 25)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 9))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 16))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 9)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 16))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 125, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 10GD | 3T | 6L | 2D | 12x12T
    @Test(.timeLimit(.minutes(1)))
    func schedule10GameDays3Times8Locations2Divisions24Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 3, 8, 24)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 12))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 12))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 240, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 11GD | 4T | 6L | 2D | 12x11T
    @Test(.timeLimit(.minutes(1)))
    func schedule11GameDays4Times6Locations2Divisions23Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (11, 4, 6, 23)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 12))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 11))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(2),
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 11))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 253, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 10GD | 4T | 6L | 2D | 11x12T
    @Test(.timeLimit(.minutes(1)))
    func schedule10GameDays4Times6Locations2Divisions23Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 6, 23)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 11))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 12))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(2),
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 11)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 230, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 10GD | 4T | 8L | 3D | 8x8x10T
    @Test(.timeLimit(.minutes(1)))
    func scheduleB2B_10GameDays4Times8Locations3Divisions26Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 8, 26)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 8))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 8))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 2, count: 10))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 15),
                StaticTime(hour: 20, minute: 15),
                StaticTime(hour: 21, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, 8)),
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, 8)),
                try Self.getDivision(dayOfWeek: .thursday, values: (gameDays, maxEntryMatchupsPerGameDay, 10))
            ],
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 260, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 11GD | 4T | 8L | 2D | 12x12T
    //@Test(.timeLimit(.minutes(1))) // TODO: support
    func scheduleB2B_11GameDays4Times8Locations2DivisionsDifferentTimes24Teams() async throws {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (11, 4, 8, 24)
        var entryDivisions = [Division.IDValue]()
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 0, count: 12))
        entryDivisions.append(contentsOf: [Division.IDValue](repeating: 1, count: 12))
        let schedule = Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .no,
            divisions: [
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .wednesday, values: (gameDays, maxEntryMatchupsPerGameDay, 12))
            ],
            divisionsCanPlayAtSameTime: false,
            entries: Self.getEntries(
                divisions: entryDivisions,
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            )
        )
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 253, data: data)
    }
}

extension ScheduleBeanBagToss {
    // MARK: 10GD | 4T | 8L | 1D | 21T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=Mjc0OTM3Ng==&arg3=Mzg4NjQ=
    @Test(.timeLimit(.minutes(1)))
    func scheduleBeanBagToss_10GameDays4Time8Locations1Division21Teams() async throws {
        let schedule = try Self.scheduleBeanBagToss_10GameDays4Time8Locations1Division21Teams()
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 210, data: data)
    }
    static func scheduleBeanBagToss_10GameDays4Time8Locations1Division21Teams(
        constraints: GenerationConstraints = .default
    ) throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 8, 21)
        return Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, teams))
            ],
            entries: Self.getEntries(
                divisions: .init(repeating: 0, count: teams),
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            ),
            constraints: constraints
        )
    }
}

extension ScheduleBeanBagToss {
    // MARK: 10GD | 4T | 6L | 2D | 23T
    // https://secure.rec1.com/MN/owatonna-mn/leagueschedule.php?arg1=MjMwMTU4Nw==&arg3=MzEwMjQ=
    @Test(.timeLimit(.minutes(1)))
    func scheduleBeanBagToss_10GameDays4Times6Locations2Division23Teams() async throws {
        let schedule = try Self.scheduleBeanBagToss_10GameDays4Times6Locations2Division23Teams()
        let data = await schedule.generate()
        try expectations(settings: schedule, matchupsCount: 230, data: data)
    }
    static func scheduleBeanBagToss_10GameDays4Times6Locations2Division23Teams(
        constraints: GenerationConstraints = .default
    ) throws -> UnitTestRuntimeSchedule {
        let maxEntryMatchupsPerGameDay:EntryMatchupsPerGameDay = 2
        let (gameDays, times, locations, teams):(DayIndex, TimeIndex, LocationIndex, Int) = (10, 4, 6, 23)
        return Self.getSchedule(
            gameDays: gameDays,
            entryMatchupsPerGameDay: maxEntryMatchupsPerGameDay,
            entriesPerLocation: 2,
            startingTimes: [
                StaticTime(hour: 18, minute: 30),
                StaticTime(hour: 19, minute: 0),
                StaticTime(hour: 19, minute: 30),
                StaticTime(hour: 20, minute: 0)
            ],
            locations: locations,
            optimizeTimes: true,
            prioritizeHomeAway: false,
            balanceHomeAway: true,
            balanceTimeStrictness: .normal,
            balanceLocationStrictness: .normal,
            gameGaps: .upTo(1),
            divisions: [
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, 12)),
                try Self.getDivision(dayOfWeek: .monday, values: (gameDays, maxEntryMatchupsPerGameDay, 11))
            ],
            entries: Self.getEntries(
                divisions: .init(repeating: 0, count: teams),
                gameDays: gameDays,
                times: times,
                locations: locations,
                teams: teams
            ),
            constraints: constraints
        )
    }
}