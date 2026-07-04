import Foundation
import SwiftData

@Model
final class Committee {
    @Attribute(.unique) var id: UUID
    var name: String
    var monthlyAmount: Decimal
    var totalMembers: Int
    var startMonth: Date
    var myCyclePosition: Int?
    var monthsCompleted: Int
    var isActive: Bool
    var createdAt: Date

    init(name: String, monthlyAmount: Decimal, totalMembers: Int, startMonth: Date, myCyclePosition: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.totalMembers = totalMembers
        self.startMonth = startMonth
        self.myCyclePosition = myCyclePosition
        self.monthsCompleted = 0
        self.isActive = true
        self.createdAt = Date()
    }

    var totalPayout: Decimal {
        monthlyAmount * Decimal(totalMembers)
    }

    var isComplete: Bool {
        monthsCompleted >= totalMembers
    }

    var remainingMonths: Int {
        max(0, totalMembers - monthsCompleted)
    }

    var totalContributed: Decimal {
        monthlyAmount * Decimal(monthsCompleted)
    }
}