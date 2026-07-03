import Foundation
import SwiftData

@Model
final class Debtor {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String?
    var email: String?
    var totalLent: Decimal
    var totalRepaid: Decimal
    var createdAt: Date
    var updatedAt: Date
    var notes: String?

    var outstandingBalance: Decimal {
        totalLent - totalRepaid
    }

    var isSettled: Bool {
        outstandingBalance == 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        email: String? = nil,
        totalLent: Decimal = 0,
        totalRepaid: Decimal = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.totalLent = totalLent
        self.totalRepaid = totalRepaid
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
    }
}