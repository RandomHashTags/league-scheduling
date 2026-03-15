
@testable import LeagueScheduling
import StaticDateTimes
import Testing

@Suite
struct CanPlayAtTests {
    @Test
    func canPlayAtNormal() {
        let times = 3
        let locations = 3

        var gameGap = GameGap.upTo(1).minMax
        var playsAt:PlaysAt.Element = []
        var playsAtTimes:PlaysAtTimes.Element = []
        var timeNumbers:AssignedTimes.Element = .init(repeating: 0, count: times)
        var locationNumbers:AssignedLocations.Element = .init(repeating: 0, count: locations)
        let maxTimeNumbers:MaximumTimeAllocations.Element = .init(repeating: 1, count: times)
        var maxLocationNumbers:MaximumLocationAllocations.Element = .init(repeating: 1, count: locations)

        var location:LocationIndex = 0
        for time in 0..<TimeIndex(times) {
            #expect(CanPlayAtNormal.test(
                time: time,
                location: location,
                allowedTimes: [0, 1, 2],
                allowedLocations: [0, 1, 2],
                playsAtTimes: playsAtTimes,
                timeNumber: timeNumbers[unchecked: time],
                locationNumber: locationNumbers[unchecked: location],
                maxTimeNumber: UInt8(maxTimeNumbers[unchecked: time]),
                maxLocationNumber: UInt8(maxLocationNumbers[unchecked: location]),
                gameGap: gameGap
            ))
            #expect(!CanPlayAtNormal.test(
                time: time,
                location: location,
                allowedTimes: [],
                allowedLocations: [],
                playsAtTimes: playsAtTimes,
                timeNumber: timeNumbers[unchecked: time],
                locationNumber: locationNumbers[unchecked: location],
                maxTimeNumber: UInt8(maxTimeNumbers[unchecked: time]),
                maxLocationNumber: UInt8(maxLocationNumbers[unchecked: location]),
                gameGap: gameGap
            ))
        }

        playsAt.insert(AvailableSlot(time: 0, location: location))
        playsAtTimes.insert(0)
        #expect(!CanPlayAtNormal.test(
            time: 0,
            location: location,
            allowedTimes: [0, 1, 2],
            allowedLocations: [0, 1, 2],
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumbers[unchecked: 0],
            locationNumber: locationNumbers[unchecked: location],
            maxTimeNumber: UInt8(maxTimeNumbers[unchecked: 0]),
            maxLocationNumber: UInt8(maxLocationNumbers[unchecked: location]),
            gameGap: gameGap
        ))

        playsAt = []
        playsAtTimes = []
        timeNumbers[0] = 1
        #expect(!CanPlayAtNormal.test(
            time: 0,
            location: location,
            allowedTimes: [0, 1, 2],
            allowedLocations: [0, 1, 2],
            playsAtTimes: playsAtTimes,
            timeNumber: timeNumbers[0],
            locationNumber: locationNumbers[unchecked: location],
            maxTimeNumber: UInt8(maxTimeNumbers[0]),
            maxLocationNumber: UInt8(maxLocationNumbers[unchecked: location]),
            gameGap: gameGap
        ))
    }
}

// MARK: Travel Durations
extension CanPlayAtTests {
    @Test
    func canPlayAtWithTravelDurations() {
        let startingTimes = [
            StaticTime(hour: 6, minute: 30),
            StaticTime(hour: 7, minute: 0),
            StaticTime(hour: 7, minute: 30),
            StaticTime(hour: 8, minute: 0)
        ]
        var matchupDuration:MatchupDuration = 0
        var travelDurations:[[MatchupDuration]] = [
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0]
        ]
        var time:TimeIndex = 0
        var location:LocationIndex = 0
        var playsAt:Set<AvailableSlot> = []
        var gameGap = GameGap.upTo(5).minMax
        
        #expect(CanPlayAtWithTravelDurations.test(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt,
            gameGap: gameGap
        ))

        matchupDuration = .minutes(30)
        playsAt = [AvailableSlot(time: 1, location: 0)]
        #expect(CanPlayAtWithTravelDurations.test(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt,
            gameGap: gameGap
        ))

        time = 2
        #expect(CanPlayAtWithTravelDurations.test(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt,
            gameGap: gameGap
        ))

        time = 0
        matchupDuration = .minutes(31)
        #expect(!CanPlayAtWithTravelDurations.test(
            startingTimes: startingTimes,
            matchupDuration: matchupDuration,
            travelDurations: travelDurations,
            time: time,
            location: location,
            playsAt: playsAt,
            gameGap: gameGap
        ))
    }
}