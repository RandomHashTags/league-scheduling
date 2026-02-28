
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct CanPlayAtTests {
    @Test
    func canPlayAt() {
        let startingTimes = [
            StaticTime(hour: 6, minute: 30),
            StaticTime(hour: 7, minute: 0),
            StaticTime(hour: 7, minute: 30)
        ]
        let locations = 3
        let matchupDuration:LeagueMatchupDuration = 0
        let travelDurations = [[LeagueMatchupDuration]]()

        var gameGap = GameGap.upTo(1).minMax
        var playsAt:PlaysAt.Element = []
        var playsAtTimes:PlaysAtTimes.Element = []
        var playsAtLocations:PlaysAtLocations.Element = []
        var timeNumbers:LeagueAssignedTimes.Element = .init(repeating: 0, count: startingTimes.count)
        var locationNumbers:LeagueAssignedLocations.Element = .init(repeating: 0, count: locations)
        let maxTimeNumbers:MaximumTimeAllocations.Element = .init(repeating: 1, count: startingTimes.count)
        var maxLocationNumbers:MaximumLocationAllocations.Element = .init(repeating: 1, count: locations)

        var location:LeagueLocationIndex = 0
        for time in 0..<LeagueTimeIndex(startingTimes.count) {
            #expect(LeagueScheduleData.canPlayAt(
                startingTimes: startingTimes,
                matchupDuration: matchupDuration,
                travelDurations: travelDurations,
                time: time,
                location: location,
                gameGap: gameGap,
                allowedTimes: [0, 1, 2],
                allowedLocations: [0, 1, 2],
                playsAt: playsAt,
                playsAtTimes: playsAtTimes,
                playsAtLocations: playsAtLocations,
                timeNumbers: timeNumbers,
                locationNumbers: locationNumbers,
                maxTimeNumbers: maxTimeNumbers,
                maxLocationNumbers: maxLocationNumbers
            ))
            #expect(!LeagueScheduleData.canPlayAt(
                startingTimes: startingTimes,
                matchupDuration: matchupDuration,
                travelDurations: travelDurations,
                time: time,
                location: location,
                gameGap: gameGap,
                allowedTimes: [],
                allowedLocations: [],
                playsAt: playsAt,
                playsAtTimes: playsAtTimes,
                playsAtLocations: playsAtLocations,
                timeNumbers: timeNumbers,
                locationNumbers: locationNumbers,
                maxTimeNumbers: maxTimeNumbers,
                maxLocationNumbers: maxLocationNumbers
            ))
        }

        playsAt.insert(LeagueAvailableSlot(time: 0, location: location))
        playsAtTimes.insert(0)
        #expect(!LeagueScheduleData.canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: 0,
            location: location,
            gameGap: gameGap,
            allowedTimes: [0, 1, 2],
            allowedLocations: [0, 1, 2],
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            timeNumbers: timeNumbers,
            locationNumbers: locationNumbers,
            maxTimeNumbers: maxTimeNumbers,
            maxLocationNumbers: maxLocationNumbers
        ))

        playsAt = []
        playsAtTimes = []
        timeNumbers[0] = 1
        #expect(!LeagueScheduleData.canPlayAt(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: 0,
            location: location,
            gameGap: gameGap,
            allowedTimes: [0, 1, 2],
            allowedLocations: [0, 1, 2],
            playsAt: playsAt,
            playsAtTimes: playsAtTimes,
            playsAtLocations: playsAtLocations,
            timeNumbers: timeNumbers,
            locationNumbers: locationNumbers,
            maxTimeNumbers: maxTimeNumbers,
            maxLocationNumbers: maxLocationNumbers
        ))
    }
}

// MARK: Travel Durations
extension CanPlayAtTests {
    @Test
    func travelDurationAllowed() {
        let startingTimes = [
            StaticTime(hour: 6, minute: 30),
            StaticTime(hour: 7, minute: 0),
            StaticTime(hour: 7, minute: 30),
            StaticTime(hour: 8, minute: 0)
        ]
        var matchupDuration:LeagueMatchupDuration = 0
        var travelDurations:[[LeagueMatchupDuration]] = [
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0]
        ]
        var time:LeagueTimeIndex = 0
        var location:LeagueLocationIndex = 0
        var playsAt:Set<LeagueAvailableSlot> = []
        
        #expect(LeagueScheduleData.travelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt
        ))

        matchupDuration = .minutes(30)
        playsAt = [LeagueAvailableSlot(time: 1, location: 0)]
        #expect(LeagueScheduleData.travelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt
        ))

        time = 2
        #expect(LeagueScheduleData.travelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt
        ))

        time = 0
        matchupDuration = .minutes(31)
        #expect(!LeagueScheduleData.travelDurationAllowed(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt
        ))
    }
}