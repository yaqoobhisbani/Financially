import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var type: TransactionType
    var amount: Decimal
    var date: Date
    var category: String?
    var desc: String?
    var fromAccountId: UUID?
    var toAccountId: UUID?
    var relatedEntityId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: TransactionType,
        amount: Decimal,
        date: Date,
        category: String? = nil,
        description: String? = nil,
        fromAccountId: UUID? = nil,
        toAccountId: UUID? = nil,
        relatedEntityId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
        self.category = category
        self.desc = description
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.relatedEntityId = relatedEntityId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}