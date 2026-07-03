import Foundation

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }

    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    var startOfYear: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year], from: self)) ?? self
    }

    var endOfYear: Date {
        Calendar.current.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) ?? self
    }

    var isInCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var isInCurrentYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    func monthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}