
#if ProtobufCodable

import FoundationEssentials
@testable import LeagueScheduling
import Testing

@Suite
struct GameGapTests {
}

// MARK: Codable
extension GameGapTests {
    @Test
    func gameGapDecode() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(CodablePayload(gameGaps: .no))
        try #require(String(decoding: data, as: UTF8.self) == "{\"gameGaps\":\"no\"}")

        let decoder = JSONDecoder()
        let test = try decoder.decode(CodablePayload.self, from: data)
        switch test.gameGaps {
        case .no:
            #expect(Bool(true))
        default:
            #expect(Bool(false))
        }
    }

    @Test
    func gameGapEncode() throws {
        let encoder = JSONEncoder()
        var payload = CodablePayload(gameGaps: .no)
        var data = try encoder.encode(payload)
        #expect(String(decoding: data, as: UTF8.self) == "{\"gameGaps\":\"no\"}")

        payload.gameGaps = .always(1)
        data = try encoder.encode(payload)
        #expect(String(decoding: data, as: UTF8.self) == "{\"gameGaps\":\"always 1\"}")

        payload.gameGaps = .upTo(1)
        data = try encoder.encode(payload)
        #expect(String(decoding: data, as: UTF8.self) == "{\"gameGaps\":\"upto 1\"}")

        payload.gameGaps = .minimumOf(1)
        data = try encoder.encode(payload)
        #expect(String(decoding: data, as: UTF8.self) == "{\"gameGaps\":\"minimumof 1\"}")
    }

    struct CodablePayload: Codable {
        var gameGaps:GameGap
    }
}

#endif