
// MARK: CustomStringConvertible
extension AvailableSlot: CustomStringConvertible {
    public var description: String {
        "T\(time)L\(location)"
    }
}

// MARK: Hashable
extension AvailableSlot: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(time)
        hasher.combine(location)
    }
}

// MARK: General
extension AvailableSlot {
    init(time: TimeIndex, location: LocationIndex) {
        self.time = time
        self.location = location
    }
}