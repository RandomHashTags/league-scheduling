
// MARK: Try redistributing
extension LeagueScheduleData {
    /// Tries to move previously scheduled matchups to later days.
    mutating func tryRedistributing(
        settings: LeagueRequestPayload.Runtime,
        generationData: inout LeagueGenerationData
    ) throws(LeagueError) {
        guard day > 0 else {
            throw .failedRedistributionRequiresPreviouslyScheduledMatchups
        }
        if assignmentState.matchupDuration > 0 {
            try tryRedistributing(
                startDayIndex: day-1,
                settings: settings,
                canPlayAt: CanPlayAtWithTravelDurations(
                    startingTimes: assignmentState.startingTimes,
                    matchupDuration: assignmentState.matchupDuration,
                    travelDurations: assignmentState.locationTravelDurations
                ),
                generationData: &generationData
            )
        } else if sameLocationIfB2B {
            try tryRedistributing(
                startDayIndex: day-1,
                settings: settings,
                canPlayAt: CanPlayAtSameLocationIfB2B(),
                generationData: &generationData
            )
        } else {
            try tryRedistributing(
                startDayIndex: day-1,
                settings: settings,
                canPlayAt: CanPlayAtNormal(),
                generationData: &generationData
            )
        }
    }

    private mutating func tryRedistributing(
        startDayIndex: LeagueDayIndex,
        settings: LeagueRequestPayload.Runtime,
        canPlayAt: borrowing some CanPlayAtProtocol & ~Copyable,
        generationData: inout LeagueGenerationData
    ) throws(LeagueError) {
        if redistributionData == nil {
            redistributionData = .init(
                dayIndex: day,
                startDayIndex: startDayIndex,
                settings: settings,
                data: self
            )
        }
        let previousSchedule = generationData.schedule
        guard redistributionData!.redistributeMatchups(
            clock: clock,
            canPlayAt: canPlayAt,
            day: day,
            gameGap: gameGap,
            assignmentState: &assignmentState,
            executionSteps: &executionSteps,
            generationData: &generationData
        ) else {
            generationData.schedule = previousSchedule
            throw .failedRedistributingMatchupsForDay(day)
        }
        redistributedMatchups = true
    }
}