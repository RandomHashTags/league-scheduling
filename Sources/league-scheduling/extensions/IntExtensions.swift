extension FixedWidthInteger {
    static func * (left: Self, right: some FixedWidthInteger) -> Self {
        return left * Self(right)
    }
    static func / (left: Self, right: some FixedWidthInteger) -> Self {
        return left / Self(right)
    }

    static func + (left: Self, right: some FixedWidthInteger) -> Self {
        return left + Self(right)
    }
    static func - (left: Self, right: some FixedWidthInteger) -> Self {
        return left - Self(right)
    }

    static func % (left: Self, right: some FixedWidthInteger) -> Self {
        return left % Self(right)
    }
}