
/// Linear Congruential Generator.
struct LCG: RandomNumberGenerator, Sendable {
    private var state:UInt64
    private let multiplier:UInt64
    private let increment:UInt64

    init(
        seed: UInt64,
        multiplier: UInt64 = 6364136223846793005,
        increment: UInt64 = 1442695040888963407
    ) {
        self.state = seed == 0 ? 1 : seed
        self.multiplier = multiplier
        self.increment = increment
    }

    mutating func next() -> UInt64 {
        // LCG formula: state = (state * multiplier + increment) % modulus
        state = state &* multiplier &+ increment
        return state
    }
}