import Foundation
import SwiftData

@Model
final class CommitteeContribution {
    @Attribute(.unique) var id: UUID
    var committeeId: UUID
    var month: Date
    var amount: Decimal
    var slots: Int?
    var sourceAccountId: UUID?
    var paidAt: Date
    var transactionId: UUID?
    var notes: String?

    init(committeeId: UUID, month: Date, amount: Decimal, sourceAccountId: UUID?, slots: Int? = 1, notes: String? = nil) {
        self.id = UUID()
        self.committeeId = committeeId
        self.month = month
        self.amount = amount
        self.slots = slots
        self.sourceAccountId = sourceAccountId
        self.paidAt = Date()
        self.notes = notes
    }
}