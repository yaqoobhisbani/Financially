import Foundation
import SwiftData

@Model
final class CommodityTrade {
    @Attribute(.unique) var id: UUID
    var holdingId: UUID
    var type: TradeType
    var commodityName: String
    var symbol: String
    var grams: Decimal
    var pricePerGram: Decimal
    var totalAmount: Decimal
    var brokerageFee: Decimal
    var tax: Decimal
    var netAmount: Decimal
    var date: Date
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        holdingId: UUID,
        type: TradeType,
        commodityName: String,
        symbol: String,
        grams: Decimal,
        pricePerGram: Decimal,
        totalAmount: Decimal,
        brokerageFee: Decimal = 0,
        tax: Decimal = 0,
        netAmount: Decimal,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.holdingId = holdingId
        self.type = type
        self.commodityName = commodityName
        self.symbol = symbol
        self.grams = grams
        self.pricePerGram = pricePerGram
        self.totalAmount = totalAmount
        self.brokerageFee = brokerageFee
        self.tax = tax
        self.netAmount = netAmount
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
}
