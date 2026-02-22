import Foundation

extension Date {
    var relativeDescription: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today, \(formatted(.dateTime.hour().minute()))"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow, \(formatted(.dateTime.hour().minute()))"
        } else if let daysUntil = calendar.dateComponents([.day], from: .now, to: self).day, daysUntil < 7 {
            return formatted(.dateTime.weekday(.wide).hour().minute())
        } else {
            return formatted(.dateTime.month(.abbreviated).day().hour().minute())
        }
    }

    var shortDate: String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    var timeOnly: String {
        formatted(.dateTime.hour().minute())
    }

    var dayOfWeek: String {
        formatted(.dateTime.weekday(.wide))
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: .now, to: self).day ?? 0
    }
}
