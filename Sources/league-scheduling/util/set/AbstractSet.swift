
protocol AbstractSet: Sendable, ~Copyable {
    associatedtype Index
    associatedtype Element:Sendable

    init()
    init(_ collection: some Collection<Element>)
    init(minimumCapacity: Int)

    var count: Int { get }
    var isEmpty: Bool { get }

    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    func contains(_ member: Element) -> Bool

    mutating func reserveCapacity(_ minimumCapacity: Int)

    /// Inserts the given element in the set if it is not already present.
    mutating func insertMember(_ member: Element)

    /// Removes the specified element from the set.
    mutating func removeMember(_ member: Element)

    mutating func removeAll()
    mutating func removeAllKeepingCapacity()
    mutating func removeAll(where condition: (Element) throws -> Bool) rethrows

    mutating func formUnion(_ other: borrowing Self)

    func randomElement() -> Element?
    func randomElement(using: inout some RandomNumberGenerator) -> Element?

    func forEach(_ body: (Element) throws -> Void) rethrows
    func forEachWithReturn<Result>(_ body: (Element) throws -> Result?) rethrows -> Result?

    //subscript(unchecked index: some FixedWidthInteger) -> Element { get set }

    func filter(_ closure: (Element) throws -> Bool) rethrows -> Self

    var first: Element? { get }
    func first(where condition: (Element) throws -> Bool) rethrows -> Element?

    /// Returns a new set with the elements that are common to both this set and
    /// the given sequence.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: Another set.
    /// - Returns: A new set.
    func intersection(_ other: borrowing Self) -> Self
}