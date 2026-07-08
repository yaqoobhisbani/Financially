import Foundation
import SwiftData

@Model
final class MutualFundHolding {
    @Attribute(.unique) var id: UUID
    var accountId: UUID
    var schemeName: String
    var fundCode: String
    var totalUnits: Decimal
    var avgNavPrice: Decimal
    var totalCost: Decimal
    var currentNavPrice: Decimal?
    var priceFetchedAt: Date?
    var cytdGainLoss: Decimal?
    var createdAt: Date

    var currentValue: Decimal {
        if let price = currentNavPrice {
            return totalUnits * price
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
        schemeName: String,
        fundCode: String,
        totalUnits: Decimal = 0,
        avgNavPrice: Decimal = 0,
        totalCost: Decimal = 0,
        currentNavPrice: Decimal? = nil,
        cytdGainLoss: Decimal? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.schemeName = schemeName
        self.fundCode = fundCode
        self.totalUnits = totalUnits
        self.avgNavPrice = avgNavPrice
        self.totalCost = totalCost
        self.currentNavPrice = currentNavPrice
        self.cytdGainLoss = cytdGainLoss
        self.createdAt = Date()
    }
}
