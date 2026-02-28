
import FoundationEssentials

extension Date {
    init?(eventDate: String) {
        let values = eventDate.split(separator: "/")
        guard values.count == 3, let year:Int = values[2].int(), let month:Int = values[0].int(), let day:Int = values[1].int() else { return nil }
        var components = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current)
        components.year = year
        components.month = month
        components.day = day
        guard let date = components.date else { return nil }
        self = date
    }
}