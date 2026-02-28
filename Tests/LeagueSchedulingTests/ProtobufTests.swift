
@testable import LeagueScheduling
import StaticDateTimes
import SwiftProtobuf
import Testing

@Suite
struct ProtobufTests {
    static let options: JSONEncodingOptions = {
        var o = JSONEncodingOptions()
        o.alwaysPrintInt64sAsNumbers = true
        o.alwaysPrintEnumsAsInts = true
        return o
    }()

    @Test
    func protobufMatchupPair() throws {
        var pair = LeagueMatchupPair(team1: 10, team2: 20)
        var binary:[UInt8] = try pair.serializedBytes()
        var json = try pair.jsonString(options: Self.options)
        #expect(binary == [8, 10, 16, 20])
        #expect(json == #"{"team1":10,"team2":20}"#)

        pair.team1 = 2
        pair.team2 = .max
        binary = try pair.serializedBytes()
        json = try pair.jsonString(options: Self.options)
        #expect(binary == [8, 2, 16, 255, 255, 255, 255, 15])
        #expect(json == #"{"team1":2,"team2":\#(LeagueEntry.IDValue.max)}"#)
    }

    @Test
    func protobufStaticTime() throws {
        var time = StaticTime(hour: 1, minute: 2)
        var binary:[UInt8] = try time.serializedBytes()
        var json = try time.jsonString(options: Self.options)
        #expect(binary == [8, 1, 16, 2])
        #expect(json == #"{"hour":1,"minute":2}"#)

        time = .init(hour: Int32.max, minute: Int32.min)
        binary = try time.serializedBytes()
        json = try time.jsonString(options: Self.options)
        #expect(binary == [8, 255, 255, 255, 255, 7, 16, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1])
        #expect(json == #"{"hour":2147483647,"minute":-2147483648}"#)
    }
}