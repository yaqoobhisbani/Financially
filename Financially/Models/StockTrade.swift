import Foundation
import SwiftData

enum TradeType: String, Codable {
    case buy
    case sell
}

@Model
final class StockTrade {
    @Attribute(.unique) var id: UUID
    var accountId: UUID
    var holdingId: UUID
    var type: TradeType
    var ticker: String
    var companyName: String
    var shares: Int
    var pricePerShare: Decimal
    var totalAmount: Decimal
    var brokerageFee: Decimal
    var tax: Decimal
    var netAmount: Decimal
    var date: Date
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        accountId: UUID,
        holdingId: UUID,
        type: TradeType,
        ticker: String,
        companyName: String,
        shares: Int,
        pricePerShare: Decimal,
        totalAmount: Decimal,
        brokerageFee: Decimal = 0,
        tax: Decimal = 0,
        netAmount: Decimal,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.holdingId = holdingId
        self.type = type
        self.ticker = ticker
        self.companyName = companyName
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.totalAmount = totalAmount
        self.brokerageFee = brokerageFee
        self.tax = tax
        self.netAmount = netAmount
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
}