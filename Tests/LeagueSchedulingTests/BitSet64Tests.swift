
@testable import LeagueScheduling
import Testing

struct BitSet64Tests {
    @Test
    func bitSet64InsertMember() {
        var s = BitSet64<UInt32>()
        for i in 0..<UInt32(64) {
            s.insertMember(i)
            #expect(s.contains(i))
        }
    }

    @Test
    func bitSet64RemoveMember() {
        var s = BitSet64<UInt32>.init(storage: .max)
        for i in 0..<UInt32(64) {
            #expect(s.contains(i))
            s.removeMember(i)
            #expect(!s.contains(i))
        }
    }

    @Test
    func bitSet64Contains() {
        let s = BitSet64<UInt32>.init(storage: 0x1010101010101010)
        #expect(!s.contains(0))
        #expect(!s.contains(1))
        #expect(!s.contains(2))
        #expect(!s.contains(3))
        #expect(s.contains(4))
        #expect(!s.contains(5))
        #expect(!s.contains(6))
        #expect(!s.contains(7))
        #expect(!s.contains(8))

        #expect(s.contains(12))
        #expect(s.contains(20))
        #expect(s.contains(28))
        #expect(s.contains(36))
        #expect(s.contains(44))
        #expect(s.contains(52))
        #expect(s.contains(60))
    }

    @Test
    func bitSet64RandomElement() {
        var s = BitSet64<UInt32>()
        #expect(s.randomElement() == nil)

        s.insertMember(8)
        #expect(s.randomElement() == 8)

        s.removeMember(8)
        #expect(s.randomElement() == nil)

        s.insertMember(65)
        #expect(s.randomElement() == nil)
    }

    @Test
    func bitSet64ForEach() {
        var s = BitSet64<UInt32>()
        s.forEach { _ in
            #expect(Bool(false))
        }

        s.insertMember(0)
        s.insertMember(32)
        s.insertMember(63)
        s.forEach { i in
            #expect(i == 0 || i == 32 || i == 63)
        }
        #expect(s.contains(0))
        #expect(s.contains(32))
        #expect(s.contains(63))
    }

    @Test
    func bitSet64Count() {
        var s = BitSet64<UInt32>()
        #expect(s.count == 0)
        #expect(s.isEmpty)

        s.insertMember(0)
        #expect(s.count == 1)
        #expect(!s.isEmpty)

        s.insertMember(64)
        #expect(s.count == 1)
        #expect(!s.isEmpty)

        s.insertMember(63)
        #expect(s.count == 2)
        #expect(!s.isEmpty)

        s.removeMember(0)
        #expect(s.count == 1)
        #expect(!s.isEmpty)
    }

    @Test
    func bitSet64FormUnion() {
        var s = BitSet64<UInt32>(storage: 0x1010101010101010)
        s.formUnion(.init(storage: 0x0101010101010101))
        #expect(s == .init(storage: 0x1111111111111111))
    }

    @Test
    func bitSet64RemoveAllWhere() {
        var s = BitSet64<UInt32>(storage: .max)
        s.removeAll(where: { $0 % 2 == 0 })
        #expect(s.storage == 0xAAAAAAAAAAAAAAAA)

        s.removeAll(where: { $0 % 1 == 0})
        #expect(s.storage == 0)
    }
}