import Foundation
import SwiftData

@Model
final class StockHolding {
    @Attribute(.unique) var id: UUID
    var accountId: UUID
    var companyName: String
    var ticker: String
    var totalShares: Int
    var avgCostPerShare: Decimal
    var totalCost: Decimal
    var totalFeesPaid: Decimal
    var currentPrice: Decimal?
    var priceFetchedAt: Date?
    var createdAt: Date

    var currentValue: Decimal {
        if let price = currentPrice {
            return Decimal(totalShares) * price
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
        accountId: UUID,
        companyName: String,
        ticker: String,
        totalShares: Int = 0,
        avgCostPerShare: Decimal = 0,
        totalCost: Decimal = 0,
        totalFeesPaid: Decimal = 0,
        currentPrice: Decimal? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.companyName = companyName
        self.ticker = ticker
        self.totalShares = totalShares
        self.avgCostPerShare = avgCostPerShare
        self.totalCost = totalCost
        self.totalFeesPaid = totalFeesPaid
        self.currentPrice = currentPrice
        self.createdAt = Date()
    }
}