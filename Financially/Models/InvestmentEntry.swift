import Foundation
import SwiftData

@Model
final class InvestmentEntry {
    @Attribute(.unique) var id: UUID
    var investmentAccountId: UUID
    var type: InvestmentEntryType
    var amount: Decimal
    var date: Date
    var period: String?
    var desc: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        investmentAccountId: UUID,
        type: InvestmentEntryType,
        amount: Decimal,
        date: Date,
        period: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.investmentAccountId = investmentAccountId
        self.type = type
        self.amount = amount
        self.date = date
        self.period = period
        self.desc = description
        self.createdAt = Date()
    }
}

enum InvestmentEntryType: String, Codable {
    case profit
    case loss
}