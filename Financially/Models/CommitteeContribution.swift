import Foundation
import SwiftData

@Model
final class CommitteeContribution {
    @Attribute(.unique) var id: UUID
    var committeeId: UUID
    var month: Date
    var amount: Decimal
    var sourceAccountId: UUID?
    var paidAt: Date
    var transactionId: UUID?
    var notes: String?

    init(committeeId: UUID, month: Date, amount: Decimal, sourceAccountId: UUID?, notes: String? = nil) {
        self.id = UUID()
        self.committeeId = committeeId
        self.month = month
        self.amount = amount
        self.sourceAccountId = sourceAccountId
        self.paidAt = Date()
        self.notes = notes
    }
}