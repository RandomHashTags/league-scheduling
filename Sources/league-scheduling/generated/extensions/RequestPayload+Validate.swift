
extension RequestPayload {
    @discardableResult
    func validateSettings(
        kind: String,
        settings: GeneralSettings,
        fallbackSettings: GeneralSettings
    ) throws(LeagueError) -> GameGap? {
        let isDefault = kind == "default"
        if isDefault || settings.hasTimeSlots {
            guard settings.timeSlots > 0 else {
                throw .malformedInput(msg: "\(kind) 'timeSlots' size needs to be > 0")
            }
        }
        if settings.hasStartingTimes {
            guard settings.startingTimes.times.count > 0 else {
                throw .malformedInput(msg: "\(kind) 'startingTimes' size needs to be > 0")
            }
        }
        if settings.hasTimeSlots && settings.hasStartingTimes {
            guard settings.timeSlots == settings.startingTimes.times.count else {
                throw .malformedInput(msg: "\(kind) 'timeSlots' and 'startingTimes' size need to be equal")
            }
        }
        if isDefault || settings.hasLocations {
            guard settings.locations > 0 else {
                throw .malformedInput(msg: "\(kind) 'locations' needs to be > 0")
            }
        }
        if isDefault || settings.hasEntryMatchupsPerGameDay {
            guard settings.entryMatchupsPerGameDay > 0 else {
                throw .malformedInput(msg: "\(kind) 'entryMatchupsPerGameDay' needs to be > 0")
            }
        }
        if settings.hasMaximumPlayableMatchups {
            guard settings.maximumPlayableMatchups.array.count == entries.count else {
                throw .malformedInput(msg: "\(kind) 'maximumPlayableMatchups' size != \(entries.count)")
            }
        }
        if isDefault || settings.hasEntriesPerLocation {
            guard settings.entriesPerLocation > 0 else {
                throw .malformedInput(msg: "\(kind) 'entriesPerLocation' needs to be > 0")
            }
        }
        let locations = settings.hasLocations ? settings.locations : fallbackSettings.locations
        if settings.hasLocationTravelDurations {
            guard settings.locationTravelDurations.locations.count == locations else {
                throw .malformedInput(msg: "\(kind) 'locationTravelDurations.locations' size != \(locations)")
            }
        }
        if settings.hasLocationTimeExclusivities {
            guard settings.locationTimeExclusivities.locations.count == locations else {
                throw .malformedInput(msg: "\(kind) 'locationTimeExclusivities.locations' size != \(locations)")
            }
        }
        if settings.hasRedistributionSettings {
            if settings.redistributionSettings.hasMinMatchupsRequired {
                guard settings.redistributionSettings.minMatchupsRequired > 0 else {
                    throw .malformedInput(msg: "\(kind) redistribution setting 'minMatchupsRequired' needs to be > 0")
                }
            }
            if settings.redistributionSettings.hasMaxMovableMatchups {
                guard settings.redistributionSettings.maxMovableMatchups > 0 else {
                    throw .malformedInput(msg: "\(kind) redistribution setting 'maxMovableMatchups' needs to be > 0")
                }
            }
        }
        if isDefault || settings.hasGameGap {
            guard let gameGap = GameGap.init(htmlInputValue: settings.gameGap) else {
                throw .malformedInput(msg: "\(kind) invalid 'gameGap' value: \(settings.gameGap)")
            }
            return gameGap
        }
        return nil
    }
}