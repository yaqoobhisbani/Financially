import Foundation
import SwiftData

@Model
final class MutualFundTrade {
    @Attribute(.unique) var id: UUID
    var accountId: UUID
    var holdingId: UUID
    var type: TradeType
    var fundCode: String
    var schemeName: String
    var units: Decimal
    var navPrice: Decimal
    var totalAmount: Decimal
    var fees: Decimal
    var netAmount: Decimal
    var date: Date
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        accountId: UUID,
        holdingId: UUID,
        type: TradeType,
        fundCode: String,
        schemeName: String,
        units: Decimal,
        navPrice: Decimal,
        totalAmount: Decimal,
        fees: Decimal = 0,
        netAmount: Decimal,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.holdingId = holdingId
        self.type = type
        self.fundCode = fundCode
        self.schemeName = schemeName
        self.units = units
        self.navPrice = navPrice
        self.totalAmount = totalAmount
        self.fees = fees
        self.netAmount = netAmount
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
}
