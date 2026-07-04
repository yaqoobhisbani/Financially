import Foundation
import SwiftData

@Model
final class CommodityHolding {
    @Attribute(.unique) var id: UUID
    var commodityName: String
    var symbol: String
    var totalGrams: Decimal
    var avgCostPerGram: Decimal
    var totalCost: Decimal
    var totalFeesPaid: Decimal
    var currentPricePerGram: Decimal?
    var priceFetchedAt: Date?
    var createdAt: Date

    var currentValue: Decimal {
        if let price = currentPricePerGram {
            return totalGrams * price
        }
        return totalCost
    }

    var unrealizedPAndL: Decimal {
        currentValue - totalCost
    }

    var returnPercentage: Decimal {
        guard totalCost > 0 else { return 0 }
        return (unrealizedPAndL / totalCost) * 100
    }

    init(
        id: UUID = UUID(),
        commodityName: String,
        symbol: String,
        totalGrams: Decimal = 0,
        avgCostPerGram: Decimal = 0,
        totalCost: Decimal = 0,
        totalFeesPaid: Decimal = 0,
        currentPricePerGram: Decimal? = nil
    ) {
        self.id = id
        self.commodityName = commodityName
        self.symbol = symbol
        self.totalGrams = totalGrams
        self.avgCostPerGram = avgCostPerGram
        self.totalCost = totalCost
        self.totalFeesPaid = totalFeesPaid
        self.currentPricePerGram = currentPricePerGram
        self.createdAt = Date()
    }
}
