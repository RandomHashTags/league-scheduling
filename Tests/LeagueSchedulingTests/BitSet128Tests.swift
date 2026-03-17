
@testable import LeagueScheduling
import Testing

struct BitSet128Tests {
    @Test
    func bitSet128InsertMember() {
        var s = BitSet128<UInt32>()
        for i in 0..<UInt32(128) {
            s.insertMember(i)
            #expect(s.contains(i))
        }
    }

    @Test
    func bitSet128RemoveMember() {
        var s = BitSet128<UInt32>.init(storage: .max)
        for i in 0..<UInt32(128) {
            #expect(s.contains(i))
            s.removeMember(i)
            #expect(!s.contains(i))
        }
    }

    @Test
    func bitSet128Contains() {
        let s = BitSet128<UInt32>.init(storage: 0x1010101010101010_1010101010101010)
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
        #expect(s.contains(68))
        #expect(s.contains(76))
        #expect(s.contains(84))
        #expect(s.contains(92))
        #expect(s.contains(100))
        #expect(s.contains(108))
        #expect(s.contains(116))
        #expect(s.contains(124))
    }

    @Test
    func bitSet128RandomElement() {
        var s = BitSet128<UInt32>()
        #expect(s.randomElement() == nil)

        s.insertMember(8)
        #expect(s.randomElement() == 8)

        s.removeMember(8)
        #expect(s.randomElement() == nil)

        s.insertMember(128)
        #expect(s.randomElement() == nil)
    }

    @Test
    func bitSet128ForEach() {
        var s = BitSet128<UInt32>()
        s.forEach { _ in
            #expect(Bool(false))
        }

        s.insertMember(0)
        s.insertMember(32)
        s.insertMember(127)
        s.forEach { i in
            #expect(i == 0 || i == 32 || i == 127)
        }
        #expect(s.contains(0))
        #expect(s.contains(32))
        #expect(s.contains(127))
    }

    @Test
    func bitSet128Count() {
        var s = BitSet128<UInt32>()
        #expect(s.count == 0)
        #expect(s.isEmpty)

        s.insertMember(0)
        #expect(s.count == 1)
        #expect(!s.isEmpty)

        s.insertMember(128)
        #expect(s.count == 1)
        #expect(!s.isEmpty)

        s.insertMember(127)
        #expect(s.count == 2)
        #expect(!s.isEmpty)

        s.removeMember(0)
        #expect(s.count == 1)
        #expect(!s.isEmpty)
    }

    @Test
    func bitSet128FormUnion() {
        var s = BitSet128<UInt32>(storage: 0x1010101010101010)
        s.formUnion(.init(storage: 0x0101010101010101))
        #expect(s == .init(storage: 0x1111111111111111))
    }
}