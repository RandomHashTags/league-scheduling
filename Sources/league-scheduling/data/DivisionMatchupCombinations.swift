
// MARK: All combinations
/// - Returns: All division matchup combinations separated by division.
/// - Usage: [`Division.IDValue`: `division matchup combinations`]
func calculateAllDivisionMatchupCombinations(
    entriesPerMatchup: EntriesPerMatchup,
    locations: LocationIndex,
    entryCountsForDivision: ContiguousArray<Int>
) -> ContiguousArray<ContiguousArray<ContiguousArray<Int>>> {
    var combinations:ContiguousArray<ContiguousArray<ContiguousArray<Int>>> = .init(repeating: [], count: entryCountsForDivision.count)
    for (divisionIndex, entryCount) in entryCountsForDivision.enumerated() {
        if entryCount > 0 {
            let matchupsCount = entryCount / entriesPerMatchup
            let upperLimit:Int
            if matchupsCount > locations { // more available matchups than locations
                upperLimit = Int(locations)
            } else {
                upperLimit = matchupsCount
            }
            for i in 0...upperLimit {
                let right = matchupsCount - i
                if i != 1 && right != 1 && right <= upperLimit {
                    var combo = ContiguousArray<Int>()
                    combo.append(i)
                    combo.append(right)
                    combinations[divisionIndex].append(combo)
                }
            }
        } else {
            combinations[divisionIndex] = []
        }
    }
    return combinations
}

// MARK: Allowed combinations
/// - Returns: Allowed division matchup combinations
/// - Usage: [`allowed matchup combination index`: [`Division.IDValue`: `division matchup combination`]]
func calculateAllowedDivisionMatchupCombinations(
    entriesPerMatchup: EntriesPerMatchup,
    locations: LocationIndex,
    entryCountsForDivision: ContiguousArray<Int>
) -> ContiguousArray<ContiguousArray<ContiguousArray<Int>>> {
    let allCombinations = calculateAllDivisionMatchupCombinations(
        entriesPerMatchup: entriesPerMatchup,
        locations: locations,
        entryCountsForDivision: entryCountsForDivision
    )
    var combinations = ContiguousArray<ContiguousArray<ContiguousArray<Int>>>()
    guard let initialResultsCount = allCombinations.first?.first?.count else { return combinations }
    var combinationBuilder = ContiguousArray<ContiguousArray<Int>>()
    combinationBuilder.reserveCapacity(entryCountsForDivision.count)
    yieldAllowedCombinations(
        allCombinations: allCombinations,
        division: 0,
        locations: locations,
        results: .init(repeating: 0, count: initialResultsCount),
        combinationBuilder: combinationBuilder
    ) {
        combinations.append($0)
    }
    return combinations
}
private func yieldAllowedCombinations(
    allCombinations: ContiguousArray<ContiguousArray<ContiguousArray<Int>>>,
    division: Division.IDValue,
    locations: LocationIndex,
    results: ContiguousArray<Int>,
    combinationBuilder: ContiguousArray<ContiguousArray<Int>>,
    yield: (_ combination: ContiguousArray<ContiguousArray<Int>>) -> Void
) {
    guard let targetCombinations = allCombinations[uncheckedPositive: division] else {
        yield(combinationBuilder)
        return
    }
    guard !targetCombinations.isEmpty else {
        yieldAllowedCombinations(
            allCombinations: allCombinations,
            division: division + 1,
            locations: locations,
            results: results,
            combinationBuilder: combinationBuilder,
            yield: yield
        )
        return
    }
    combinationLoop:
    for combination in targetCombinations {
        let combined = zip(results, combination).map { $0 + $1 }
        for value in combined {
            if value > locations {
                continue combinationLoop
            }
        }
        var builder = combinationBuilder
        builder.append(combination)
        yieldAllowedCombinations(
            allCombinations: allCombinations,
            division: division + 1,
            locations: locations,
            results: ContiguousArray(combined),
            combinationBuilder: builder,
            yield: yield
        )
    }
}