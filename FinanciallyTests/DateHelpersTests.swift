import Testing
import Foundation
@testable import Financially

@Suite("Date+Helpers")
struct DateHelpersTests {
    private var calendar: Calendar { Calendar.current }

    @Test func startOfDayZeroesTimeComponents() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 14, minute: 30))!
        let start = date.startOfDay
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func endOfDayIsOneSecondBeforeNextDay() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 10))!
        let end = date.endOfDay
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: date.startOfDay)!
        #expect(end < nextDayStart)
        #expect(nextDayStart.timeIntervalSince(end) == 1)
    }

    @Test func startOfMonthResetsToFirstDay() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let start = date.startOfMonth
        let components = calendar.dateComponents([.day], from: start)
        #expect(components.day == 1)
    }

    @Test func startOfYearResetsToJanuaryFirst() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let start = date.startOfYear
        let components = calendar.dateComponents([.month, .day], from: start)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test func isInCurrentMonthTrueForToday() {
        #expect(Date().isInCurrentMonth)
    }

    @Test func isInCurrentMonthFalseForLastYear() {
        let lastYear = calendar.date(byAdding: .year, value: -1, to: Date())!
        #expect(!lastYear.isInCurrentMonth)
    }
}
