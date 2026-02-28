
// MARK: Try redistributing
extension LeagueScheduleData {
    mutating func tryRedistributing(
        settings: LeagueRequestPayload.Runtime,
        generationData: inout LeagueGenerationData
    ) throws(LeagueError) {
        guard day > 0 else {
            throw .failedRedistributionRequiresPreviouslyScheduledMatchups
        }
        try tryRedistributing(
            startDayIndex: day-1,
            settings: settings,
            generationData: &generationData
        )
    }

    mutating func tryRedistributing(
        startDayIndex: LeagueDayIndex,
        settings: LeagueRequestPayload.Runtime,
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
            canPlayAtFunc: canPlayAtFunctions().0,
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