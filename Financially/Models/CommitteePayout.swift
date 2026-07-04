import Foundation
import SwiftData

@Model
final class CommitteePayout {
    @Attribute(.unique) var id: UUID
    var committeeId: UUID
    var month: Date
    var amount: Decimal
    var destinationAccountId: UUID
    var receivedAt: Date
    var transactionId: UUID?
    var notes: String?

    init(committeeId: UUID, month: Date, amount: Decimal, destinationAccountId: UUID, notes: String? = nil) {
        self.id = UUID()
        self.committeeId = committeeId
        self.month = month
        self.amount = amount
        self.destinationAccountId = destinationAccountId
        self.receivedAt = Date()
        self.notes = notes
    }
}