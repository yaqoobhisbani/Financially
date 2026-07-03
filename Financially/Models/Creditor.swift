import Foundation
import SwiftData

@Model
final class Creditor {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String?
    var totalReceived: Decimal
    var totalReturned: Decimal
    var createdAt: Date
    var updatedAt: Date
    var notes: String?

    var outstandingBalance: Decimal {
        totalReceived - totalReturned
    }

    var isSettled: Bool {
        outstandingBalance == 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        totalReceived: Decimal = 0,
        totalReturned: Decimal = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.totalReceived = totalReceived
        self.totalReturned = totalReturned
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
    }
}