import Foundation
import SwiftData

@Model
final class LedgerEntry {
    @Attribute(.unique) var id: UUID
    var transactionId: UUID
    var accountId: UUID
    var entryType: EntryType
    var amount: Decimal
    var runningBalance: Decimal
    var date: Date
    var createdAt: Date

    var account: Account?

    init(
        id: UUID = UUID(),
        transactionId: UUID,
        accountId: UUID,
        entryType: EntryType,
        amount: Decimal,
        runningBalance: Decimal,
        date: Date
    ) {
        self.id = id
        self.transactionId = transactionId
        self.accountId = accountId
        self.entryType = entryType
        self.amount = amount
        self.runningBalance = runningBalance
        self.date = date
        self.createdAt = Date()
    }
}