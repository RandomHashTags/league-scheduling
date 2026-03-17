# League Scheduling's Methodology

**Author:** Evan Anderson  
**Project:** League Scheduling  
**Repository:** https://github.com/RandomHashTags/league-scheduling  
**License:** AGPLv3  
**Published:** March 17, 2026  

> This document is a defensive publication. It discloses the algorithms, data structures, and methods implemented in the League Scheduling library in order to establish prior art as of the date of publication, preventing these techniques from being patented by any party.

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Core Concepts and Terminology](#2-core-concepts-and-terminology)
3. [Input Model](#3-input-model)
4. [High-Level Generation Pipeline](#4-high-level-generation-pipeline)
5. [Concurrent Multi-Division Scheduling](#5-concurrent-multi-division-scheduling)
6. [Assignment State](#6-assignment-state)
7. [Remaining Allocations](#7-remaining-allocations)
8. [Matchup Selection Algorithm](#8-matchup-selection-algorithm)
9. [Home/Away Balancing](#9-homeaway-balancing)
10. [Slot Selection](#10-slot-selection)
11. [Constraint Checking](#11-constraint-checking)
12. [Travel Duration Constraints](#12-travel-duration-constraints)
13. [The Shuffle Mechanism](#13-the-shuffle-mechanism)
14. [Back-to-Back Scheduling](#14-back-to-back-scheduling)
15. [Snapshot and Backtracking](#15-snapshot-and-backtracking)
16. [Matchup Redistribution](#16-matchup-redistribution)
17. [Balance Strictness](#17-balance-strictness)
18. [Error Handling and Timeouts](#18-error-handling-and-timeouts)
19. [Serialization](#19-serialization)

---

## 1. Problem Statement

League scheduling is the combinatorial problem of assigning a set of matchups between competing entries (teams) to specific time slots and locations across a sequence of game days, subject to a large number of hard and soft constraints. Hard constraints include entry availability, location capacity, game gaps between consecutive matchups, and maximum matchup counts. Soft constraints include fairness of time slot distribution, fairness of location distribution, and balance of home/away designations.

The problem is NP-hard in general — for non-trivial configurations the search space is combinatorially explosive and does not admit a closed-form optimal solution. This library addresses the problem through a combination of greedy prioritized assignment, constraint-aware slot intersection, deterministic fairness heuristics, and stochastic local search (shuffle-and-retry). The approach is designed to produce fair, valid schedules rapidly in practice without guaranteeing global optimality.

---

## 2. Core Concepts and Terminology

- **Entry**: A participating team or competitor, identified by a zero-based integer index (`UInt32`).
- **Division**: A grouping of entries that share scheduling rules. Entries only play against members of their own division unless cross-division play is configured.
- **Game Day**: A discrete scheduling unit (an index, `DayIndex`) on which matchups are assigned.
- **Slot**: A tuple of `(time: TimeIndex, location: LocationIndex)` representing a specific time and location at which a matchup can be played (`AvailableSlot`).
- **Matchup Pair**: An unordered pair of entries that are to play each other (`MatchupPair`).
- **Matchup**: A fully assigned game: a matchup pair bound to a slot on a game day, with home and away designations (`Matchup`).
- **Game Gap**: A constraint defining the minimum and/or maximum number of time-slot indices that must separate two matchups played by the same entry on the same game day.
- **Remaining Allocations**: For each entry, the set of slots still available to that entry on the current game day, after accounting for all constraints and previously assigned matchups.

---

## 3. Input Model

Inputs are provided via a `RequestPayload` and serialized using Protocol Buffers. The key inputs are:

- **entries**: A list of entries, each carrying their allowed game days, allowed game day bye indexes, per-day allowed time sets, per-day allowed location sets, division membership, designated 'home' locations, and per-day maximum number of matchups.
- **divisions**: Per-division configuration including the day of week on which the division plays, allowed game days, allowed game day bye indexes, per-day game gaps, per-day allowed time sets, per-day allowed location sets, per-day matchup durations, location availability, location travel durations, maximum same-opponent matchup caps, and cross-division opponent lists.
- **gameDays**: The total number of game days to be scheduled.
- **settings**: Default schedule settings ([General Settings](#general-settings)) that all day settings fallback to use.
- **individualDaySettings**: Optional per-day settings ([General Settings](#general-settings)). Per-day overrides for most settings are supported, allowing distinct configurations for individual game days within a single schedule.
- **generationConstraints**: Optional constraints that control how certain conditions are handled during the schedule generation process.

### General Settings

- **gameGap**: See [Core Concepts and Terminology](#2-core-concepts-and-terminology).
- **entriesPerLocation**: The number of entries occupying a single location simultaneously (typically 2 for head-to-head competition).
- **timeSlots**: The total number of available time slots.
- **startingTimes**: Wall-clock times associated with each time index.
- **locations**: The total number of available locations.
- **entryMatchupsPerGameDay**: The maximum number of matchups a single entry may play on a single game day.
- **maximumPlayableMatchups**: A per-entry cap on the total number of matchups across the entire schedule.
- **matchupDuration**: The duration in seconds that a matchup occupies at its assigned location.
- **locationTimeExclusivities**: A mapping of which time slots are available at which locations, allowing per-location time restrictions.
- **locationTravelDurations**: A matrix of travel times between all pairs of locations, used when an entry plays multiple matchups on the same day at different locations.
- **balanceTimeStrictness & balanceLocationStrictness**: Enumerated strictness levels (`LENIENT`, `RELAXED`, `NORMAL`, `VERY`) governing how tightly time and location assignments must be equalized across entries. See [Balance Strictness](#17-balance-strictness).
- **balancedTimes & balancedLocations**: Set of time and location indexes where the associated strictness applies to.
- **redistributionSettings**: Controls for moving previously scheduled matchups to later game days to ensure all game days receive the required minimum number of matchups.
- **flags**: Packed bit field encoding boolean settings: `optimizeTimes`, `prioritizeEarlierTimes`, `prioritizeHomeAway`, `balanceHomeAway`, `sameLocationIfB2B`.

---

## 4. High-Level Generation Pipeline

Schedule generation proceeds as follows:

```
For each day of week group (via concurrent task):
  Initialize LeagueScheduleData from snapshot
  For each game day index:
    Take a snapshot of current state (todayData)
    Attempt to assign all slots for this day
    If assignment succeeds:
      Append snapshot to history
      Advance to next day
    Else if regeneration attempts remain:
      Reload todayData snapshot
      Retry assignment
    Else if day > 0:
      Decrement day index
      Reload prior day's snapshot (backtrack)
      Retry prior day
    Else:
      Fail with error
```

Within each game day, the assignment process is:

1. Compute available slots for the day (the Cartesian product of time indices and location indices, filtered by `locationTimeExclusivities`)
2. Compute the set of all matchup pairs that remain to be scheduled for the current group of entries
3. Determine whether the day uses back-to-back scheduling (`gameGap.min == 1 && gameGap.max == 1` with `entryMatchupsPerGameDay > 1`) and route to the appropriate assignment path
4. Iteratively select and assign matchup pairs to slots until all expected matchups for the day are placed or assignment fails

The process operates under a 60-second wall-clock timeout by default (configurable through the `RequestPayload`'s `generationConstraints`) which is enforced via Swift's structured concurrency (`withThrowingTaskGroup`).

---

## 5. Concurrent Multi-Division Scheduling

Divisions are grouped by their `dayOfWeek` setting. Each group of divisions is scheduled independently and concurrently using Swift's `async`/`await` task group model. A single `LeagueScheduleDataSnapshot` is created upfront and each concurrent task instantiates its own `LeagueScheduleData` from that snapshot, ensuring no shared mutable state between concurrent schedulers.

This design allows divisions that play on different days of the week to be scheduled in parallel, exploiting multiple CPU cores for workloads with multiple non-overlapping division groups.

---

## 6. Assignment State

`AssignmentState` is the central mutable data structure tracking all scheduling decisions for the current generation pass. It contains:

- `numberOfAssignedMatchups`: Per-entry total matchup count across the entire schedule.
- `remainingAllocations`: Per-entry set of slots still available on the current game day.
- `recurringDayLimits`: Per-entry-pair day index after which the pair may next be scheduled, enforcing minimum gaps between rematches.
- `assignedTimes`: Per-entry count of how many times each time index has been used across the schedule.
- `assignedLocations`: Per-entry count of how many times each location index has been used across the schedule.
- `maxTimeAllocations`: Per-entry per-time-index ceiling for the number of times that time may be assigned, derived from the total matchup count and the number of available times, subject to balance strictness.
- `maxLocationAllocations`: Analogous to `maxTimeAllocations` but for locations.
- `assignedEntryHomeAways`: A 2D structure tracking, for each ordered pair of entries (A, B), how many times A has been home and away against B.
- `homeMatchups` / `awayMatchups`: Per-entry total home and away counts across the schedule.
- `allMatchups` / `allDivisionMatchups`: The complete set of all matchup pairs for the schedule, and the same broken down by division.
- `availableMatchups`: The set of matchup pairs remaining that can be scheduled.
- `prioritizedEntries`: The set of entries whose matchups should be prioritized in the current assignment iteration.
- `availableSlots`: The set of `(time, location)` slots available for assignment on the current game day.
- `playsAt` / `playsAtTimes` / `playsAtLocations`: Per-entry records of which slots have been assigned to that entry on the current game day, used for same-day gap checking.
- `matchups`: The set of matchups successfully assigned for the day.
- `shuffleHistory`: An array recording all the shuffle actions taken across the schedule.

`AssignmentState` is non-copyable by default (using Swift's `~Copyable` mechanism for performance), with explicit `copy()` and `snapshot()` operations used only when checkpointing is required.

---

## 7. Remaining Allocations

Before each game day's assignment begins, and after each successful matchup assignment, remaining allocations are recalculated for all entries involved in pending matchups.

For each entry, the remaining allocations start as the full set of available slots for the day. Slots are then removed from an entry's remaining set if:

- The entry has already reached its `maxTimeAllocations` ceiling for that slot's time index.
- The entry has already reached its `maxLocationAllocations` ceiling for that slot's location index.
- The constraint check `canPlayAt` fails for that slot given the entry's already-assigned matchups on the same day (accounting for game gaps, travel durations, and same-day overlap).

The playable slot set for a matchup pair is computed as the set intersection of the two entries' individual remaining allocation sets:

```
playableSlots(pair) = remainingAllocations[pair.team1] ∩ remainingAllocations[pair.team2]
```

This intersection is the candidate set for slot assignment for that pair on the current day.

---

## 8. Matchup Selection Algorithm

Matchup pairs are selected for assignment one at a time, in priority order. The priority function is deterministic with a stochastic tiebreaker pool to prevent repetitive assignment patterns across regeneration attempts.

**PrioritizedMatchups** is a sorted structure derived from the current `availableMatchups` and `prioritizedEntries`. Matchups involving entries that have fewer remaining available slots are surfaced first, ensuring the most-constrained pairs are assigned earliest.

**selectMatchup** iterates through the prioritized matchups and scores each candidate pair according to the following criteria, evaluated in order:

1. **Minimum matchups played so far** (`minMatchupsPlayedSoFar`): Of the two entries in the pair, the minimum number of total matchups either has been assigned across the entire schedule. Pairs where one or both entries have played fewer games overall are prioritized — this is the primary fairness driver, ensuring no entry consistently plays more than others.

2. **Total matchups played so far** (`totalMatchupsPlayedSoFar`): The sum of both entries' total matchup counts. Used as a secondary tiebreaker when the minimum values are equal.

3. **Remaining allocations**: The count of playable slots available for the pair. Pairs with fewer playable slots are given priority, as they are harder to schedule and become impossible if deferred too long.

4. **Remaining matchup count**: How many total matchups the pair still has to be scheduled. Pairs with fewer remaining matchups are prioritized.

5. **Recurring day limit**: Whether the pair's recurring day limit (the minimum day index before this pair can be rescheduled) has been satisfied.

When multiple pairs score identically across all criteria, they are placed into an equal-priority pool and one is selected at random. This randomness is the source of schedule variety across repeated generation attempts for the same configuration, and prevents the algorithm from always producing identical schedules when regenerating after a failure.

Failed matchup selections (pairs that could not be assigned to any slot) are tracked per-assignment-index in `failedMatchupSelections`, and those pairs are skipped in subsequent selection rounds within the same day to prevent infinite loops.

---

## 9. Home/Away Balancing

After a matchup pair is selected but before it is assigned to a slot, the home/away orientation of the pair is resolved.

The algorithm examines `assignedEntryHomeAways[team1][team2]`:

- If team1 has been home against team2 fewer times than away, team1 remains home.
- If team1 has been home against team2 more times than away, the pair is swapped (team2 becomes home).
- If the counts are equal, the global home/away totals for each entry (`homeMatchups`, `awayMatchups`) are consulted:
  - The entry with fewer total home games is assigned home.
  - If those are equal, the entry with fewer total away games is assigned home.
  - If all counts are equal, home/away is assigned randomly.

This mechanism ensures that over the course of a schedule, both the per-opponent home/away balance and the global home/away balance converge toward equality, subject to the mathematical constraints of the total matchup count.

---

## 10. Slot Selection

Once a matchup pair and its home/away orientation are resolved, a slot is selected from the pair's playable slots. Three slot selection strategies are implemented, chosen at configuration time:

**SelectSlotNormal**: Selects the slot that minimizes the combined deviation from the target time and location allocation counts for both entries. Specifically, it scores each candidate slot by comparing each entry's current assignment count for that slot's time and location against the entry's maximum allowed allocation for that time/location. Slots where both entries are furthest below their allocation ceiling are preferred, producing a balanced distribution of time and location usage.

**SelectSlotEarliestTime**: Among the slots scored by `SelectSlotNormal`, additionally prefers slots with lower time indices, causing the scheduler to fill earlier time slots first before later ones.

**SelectSlotEarliestTimeAndSameLocationIfB2B**: Used in back-to-back configurations. When a team already has a matchup assigned on the current game day (i.e., the proposed slot is temporally adjacent to an existing assignment), the algorithm preferentially assigns the new matchup to the same location as the existing one, minimizing location changes between consecutive games. Non-back-to-back slots are collected separately and returned only if no back-to-back same-location slot is available.

---

## 11. Constraint Checking

All slot eligibility checks are routed through a `CanPlayAtProtocol` implementation, of which three variants exist:

**CanPlayAtNormal**: A slot `(time, location)` is valid for an entry if:
- The time is in the entry's allowed times for the day.
- The location is in the entry's allowed locations for the day.
- The entry has not already played at that time on the current day (`playsAtTimes` does not contain `time`).
- The entry's `assignedTimes[time]` count is below its `maxTimeAllocations[time]` ceiling.
- The entry's `assignedLocations[location]` count is below its `maxLocationAllocations[location]` ceiling.

**CanPlayAtSameLocationIfB2B**: Extends `CanPlayAtNormal` with additional logic for back-to-back configurations where teams are required to play their consecutive same-day games at the same location.

**CanPlayAtWithTravelDurations**: Extends `CanPlayAtNormal` by additionally verifying that if the entry already has a matchup assigned on the current day, sufficient time elapses between the end of that matchup (plus travel from its location to the candidate location) and the start of the candidate slot. Given a matchup duration `D` and travel duration `T` between the two locations, the constraint is:

```
startTime[candidateSlot.time] ≥ startTime[closestExistingSlot.time] + D + T
```

or symmetrically if the candidate is earlier than the existing assignment:

```
startTime[candidateSlot.time] + D + T ≤ startTime[closestExistingSlot.time]
```

where `closestExistingSlot` is the already-assigned slot on the same day with the smallest time-index distance from the candidate.

---

## 12. Travel Duration Constraints

Travel durations are expressed as a square matrix of type `[[MatchupDuration]]` (indexed `[fromLocation][toLocation]`), where each value is the travel time in seconds between two locations.

When `CanPlayAtWithTravelDurations` is active, the scheduler enforces that no entry is assigned to two matchups on the same day where the time between the end of the first matchup and the start of the second (accounting for travel between their respective locations) is negative. This prevents physically impossible scheduling of a team at a distant venue immediately after a game at another venue, or with insufficient travel time between them.

---

## 13. The Shuffle Mechanism

When a selected matchup pair has no valid playable slots (the intersection of the two entries' remaining allocations is empty), the scheduler attempts a shuffle operation before abandoning the pair.

The shuffle searches the set of already-assigned matchups for the current day. For each assigned matchup, it attempts to find a slot that:
- Is currently available (not yet assigned).
- Is reachable by the already-assigned matchup (satisfies `canPlayAt` for both of the assigned matchup's entries at the new slot).
- After the assigned matchup vacates its current slot, that freed slot becomes valid for the originally failing matchup pair.

If such a swap is found, the existing matchup is moved to the new slot, freeing the original slot for the failing pair. The swap is recorded in `shuffleHistory` with the day index, original slot, new slot, and pair.

This is a form of single-step local search: rather than abandoning the entire day's assignment on the first conflict, the scheduler attempts to locally rearrange existing assignments to accommodate the failing matchup. If no shuffle resolves the conflict, the pair is removed from `availableMatchups` for this attempt and the day assignment either continues without it or triggers a regeneration.

---

## 14. Back-to-Back Scheduling

When `entryMatchupsPerGameDay > 1` and `gameGap.min == 1 && gameGap.max == 1`, the scheduler uses a specialized back-to-back (B2B) assignment path (`assignSlotsB2B`).

In this mode, multiple matchups per entry per day must be assigned at consecutive time slots. The scheduler processes divisions independently within each game day, using precomputed `allowedDivisionCombinations` — a structure describing how many matchup blocks each division is to contribute at each time combination.

For each division combination:
1. Division-specific available matchups are loaded into the assignment state.
2. Disallowed times are tracked to prevent time collisions between different divisions sharing the same day.
3. Matchup blocks are assigned time-by-time within each division's allocation, with the `SelectSlotEarliestTimeAndSameLocationIfB2B` strategy preferring same-location assignments for consecutive games.
4. Time allocations are accumulated across divisions to prevent double-booking a time slot.

If a particular combination fails, the scheduler falls through to the next combination in the precomputed list. If all combinations fail, the assignment state is restored from a copy taken at the start of the B2B attempt and the day's assignment is retried.

---

## 15. Snapshot and Backtracking

The scheduler maintains a stack of `LeagueScheduleDataSnapshot` objects, one per successfully completed game day. A snapshot captures the full state of `LeagueScheduleData` at a point in time, including the assignment state, recurring day limits, division combinations, and execution history.

When a game day fails to schedule after a configurable number of regeneration attempts (`regenerationAttemptsThreshold` generation constraint), the scheduler backtracks:

1. The day index is decremented.
2. The snapshot for the prior day is restored.
3. The prior day's scheduled matchups are cleared.
4. The scheduler retries assignment of the prior day from its restored state.

This bounded backtracking allows recovery from locally infeasible states without restarting the entire schedule from day zero. Negative day index failures (backtracking past day zero) are tracked separately and trigger a full regeneration attempt.

---

## 16. Matchup Redistribution

When redistribution is enabled and the total number of schedulable matchups is smaller than `gameDays × slotsPerDay`, some game days would otherwise be empty or underpopulated. The redistribution mechanism moves previously assigned matchups from earlier days to later days to ensure all game days receive at least `minMatchupsRequired` matchups.

The redistribution process:
1. Iterates backwards through previously scheduled days starting from `startDayIndex`.
2. For each already-assigned matchup on a prior day, checks whether both entries are available at any slot on the current day (by running the same `canPlayAt` constraint checks used during initial assignment).
3. The matchup is temporarily unassigned from its original day's allocation data to check whether it can be moved. If the matchup is selected to be moved, it is recorded in the `redistributed` set to prevent the same matchup from being moved multiple times.
4. The process continues until `maxMovableMatchups` matchups have been redistributed or no more valid candidates exist.

Redistribution does not schedule entirely new matchups; it only relocates already-planned matchups to ensure even game day utilization.

---

## 17. Balance Strictness

Maximum time and location allocation ceilings (`maxTimeAllocations`, `maxLocationAllocations`) are computed per entry from the entry's total maximum playable matchup count, divided evenly across the available time slots (or locations), subject to the balance strictness level:

- **VERY**: Ceiling is `⌊totalMatchups / availableSlots⌋` (perfect floor division). Enforces the strictest possible balance, preventing any time or location from being used more than the minimum.
- **NORMAL**: Ceiling is `VERY + 1`. Enforces the mathematically ideal ceiling without rounding leniency.
- **RELAXED**: Ceiling is `NORMAL + 1`. Allows slight over-allocation beyond the mathematically ideal even distribution.
- **LENIENT**: No ceiling is enforced; entries may use any time or location as many times as needed.

When `balancedTimes` or `balancedLocations` are specified, only the designated subset of time or location indices are subject to balancing; others are excluded from the ceiling computation and allowed unconstrained usage.

---

## 18. Error Handling and Timeouts

The scheduler defines a typed error enumeration (`LeagueError`) with the following distinct failure cases:

- `malformedInput`: Input validation failure (e.g., mismatched array sizes, zero-value required fields, invalid game gap strings).
- `malformedHTMLDateInput`: Failure to parse a date value from HTML date format.
- `failedNegativeDayIndex`: Backtracking past day zero without achieving a valid schedule.
- `failedZeroExpectedMatchupsForDay`: A game day has zero matchups to assign despite being scheduled, indicating misconfiguration.
- `failedAssignment`: The scheduler exhausted its regeneration attempt limit without successfully assigning all matchups for a day. The error message includes the balance strictness level to guide the user toward relaxing constraints.
- `failedRedistributionRequiresPreviouslyScheduledMatchups`: Redistribution was requested but no previously scheduled matchups exist.
- `failedRedistributingMatchupsForDay`: Redistribution failed for a specific day.
- `timedOut`: The provided wall-clock timeout was reached before schedule generation completed.

All errors include descriptive human-readable messages guiding the user toward resolution (e.g., suggesting retry, relaxing strictness, or rechecking configuration).

---

## 19. Serialization

All input and output structures are defined using Protocol Buffers (proto3) and compiled to Swift using `swift-protobuf`. This provides:

- Language-agnostic schema definitions, enabling integration with non-Swift clients via standard Protobuf tooling.
- Compact binary serialization suitable for network transport or persistent storage of schedule requests and results.
- Explicit optional field semantics, distinguishing between "field not set" and "field set to default value" in per-day override configurations.

Key serialized types include `RequestPayload`, `GeneralSettings`, `Division`, `Entry`, `RedistributionSettings`, `LocationTravelDurations`, `LocationTimeExclusivities`, and `GenerationConstraints`.

---

*This document describes the methodology of the League Scheduling library as implemented in its Swift source code. It is published to establish prior art and does not constitute a warranty of fitness for any purpose. The full source code is available at the repository link above under the AGPLv3 license.*