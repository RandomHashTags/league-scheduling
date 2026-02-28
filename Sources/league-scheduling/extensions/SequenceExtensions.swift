extension Sequence {
    /// - Complexity: O(_n_), where _n_ is the length of the sequence.
    func compactMapSet<T, E: Error>(minimumCapacity: Int, _ transform: (Element) throws(E) -> T?) rethrows -> Set<T> {
        var set = Set<T>(minimumCapacity: minimumCapacity)
        for element in self {
            if let value = try transform(element) {
                set.insert(value)
            }
        }
        return set
    }

    /// - Complexity: O(_n_), where _n_ is the length of the sequence.
    func compactMapSet<T, E: Error>(_ transform: (Element) throws(E) -> T?) rethrows -> Set<T> {
        return try Set(self.compactMap(transform))
    }
}

// MARK: Array
extension Array {
    init(repeating element: Element, count: some FixedWidthInteger) {
        self = .init(repeating: element, count: Int(count))
    }

    /// - Warning: `index` MUST be `>= startIndex`!
    subscript(uncheckedPositive index: Self.Index) -> Element? {
        guard index < endIndex else { return nil }
        #if UncheckedArraySubscript
        return withUnsafeBufferPointer { $0[index] }
        #else
        return self[index]
        #endif
    }

    /// - Warning: `index` MUST be `>= startIndex`!
    subscript(uncheckedPositive index: some FixedWidthInteger) -> Element? {
        let index = self.index(startIndex, offsetBy: Int(index))
        guard index < endIndex else { return nil }
        #if UncheckedArraySubscript
        return withUnsafeBufferPointer { $0[index] }
        #else
        return self[index]
        #endif
    }

    /// - Warning: `index` MUST be `>= startIndex && < endIndex`!
    subscript(unchecked index: some FixedWidthInteger) -> Element {
        get {
            #if UncheckedArraySubscript
            return withUnsafeBufferPointer { $0[Int(index)] }
            #else
            return self[Int(index)]
            #endif
        }
        set {
            #if UncheckedArraySubscript
            withUnsafeMutableBufferPointer { $0[Int(index)] = newValue }
            #else
            self[Int(index)] = newValue
            #endif
        }
    }

    mutating func reserveCapacity(_ capacity: some FixedWidthInteger) {
        self.reserveCapacity(Int(capacity))
    }
}

// MARK: ContiguousArray
extension ContiguousArray {
    init(repeating element: Element, count: some FixedWidthInteger) {
        self = .init(repeating: element, count: Int(count))
    }

    mutating func reserveCapacity(_ capacity: some FixedWidthInteger) {
        self.reserveCapacity(Int(capacity))
    }

    /// - Warning: `index` MUST be `>= startIndex`!
    subscript(uncheckedPositive index: Self.Index) -> Element? {
        guard index < endIndex else { return nil }
        #if UncheckedArraySubscript
        return withUnsafeBufferPointer { $0[index] }
        #else
        return self[index]
        #endif
    }

    /// - Warning: `index` MUST be `>= startIndex`!
    subscript(uncheckedPositive index: some FixedWidthInteger) -> Element? {
        let index = self.index(startIndex, offsetBy: Int(index))
        guard index < endIndex else { return nil }
        #if UncheckedArraySubscript
        return withUnsafeBufferPointer { $0[index] }
        #else
        return self[index]
        #endif
    }

    /// - Warning: `index` MUST be `>= startIndex && < endIndex`!
    subscript(unchecked index: some FixedWidthInteger) -> Element {
        get {
            #if UncheckedArraySubscript
            return withUnsafeBufferPointer { $0[Int(index)] }
            #else
            return self[Int(index)]
            #endif
        }
        set {
            #if UncheckedArraySubscript
            withUnsafeMutableBufferPointer { $0[Int(index)] = newValue }
            #else
            self[Int(index)] = newValue
            #endif
        }
    }
}

// MARK: Set
extension Set {
    init(minimumCapacity: some FixedWidthInteger) {
        self.init(minimumCapacity: Int(minimumCapacity))
    }
}