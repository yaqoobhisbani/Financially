import Foundation
import SwiftData

@Observable
final class CommodityTradeViewModel {
    private let modelContext: ModelContext
    let commodityList: [CommodityInfo]
    let holdings: [CommodityHolding]

    init(modelContext: ModelContext, commodityList: [CommodityInfo], holdings: [CommodityHolding]) {
        self.modelContext = modelContext
        self.commodityList = commodityList
        self.holdings = holdings
    }

    var activeHoldings: [CommodityHolding] {
        holdings.filter { $0.totalGrams > 0 }
    }

    private func findOrCreateHolding(symbol: String, commodityName: String, currentPricePerGram: Decimal) -> CommodityHolding {
        if let existing = holdings.first(where: { $0.symbol == symbol }) {
            return existing
        }
        let holding = CommodityHolding(commodityName: commodityName, symbol: symbol, currentPricePerGram: currentPricePerGram)
        modelContext.insert(holding)
        return holding
    }

    func buy(symbol: String, commodityName: String, grams: Decimal, pricePerGram: Decimal, brokerageFee: Decimal, tax: Decimal, netAmount: Decimal, date: Date, notes: String?) {
        let holding = findOrCreateHolding(symbol: symbol, commodityName: commodityName, currentPricePerGram: pricePerGram)
        let total = grams * pricePerGram
        let fees = brokerageFee + tax

        let trade = CommodityTrade(
            holdingId: holding.id,
            type: .buy,
            commodityName: commodityName,
            symbol: symbol,
            grams: grams,
            pricePerGram: pricePerGram,
            totalAmount: total,
            brokerageFee: brokerageFee,
            tax: tax,
            netAmount: netAmount,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let newTotalGrams = holding.totalGrams + grams
        let newCost = holding.totalCost + total
        holding.totalGrams = newTotalGrams
        holding.totalCost = newCost
        holding.totalFeesPaid += fees
        holding.avgCostPerGram = newTotalGrams > 0 ? newCost / newTotalGrams : 0
    }

    func sell(holding: CommodityHolding, grams: Decimal, pricePerGram: Decimal, brokerageFee: Decimal, tax: Decimal, netProceeds: Decimal, date: Date, notes: String?) {
        let total = grams * pricePerGram
        let fees = brokerageFee + tax

        let trade = CommodityTrade(
            holdingId: holding.id,
            type: .sell,
            commodityName: holding.commodityName,
            symbol: holding.symbol,
            grams: grams,
            pricePerGram: pricePerGram,
            totalAmount: total,
            brokerageFee: brokerageFee,
            tax: tax,
            netAmount: netProceeds,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let remainingGrams = holding.totalGrams - grams
        if remainingGrams == 0 {
            holding.totalGrams = 0
            holding.totalCost = 0
            holding.avgCostPerGram = 0
        } else {
            let avgCostPerGram = holding.totalCost / holding.totalGrams
            holding.totalCost -= grams * avgCostPerGram
            holding.totalGrams = remainingGrams
            holding.avgCostPerGram = holding.totalGrams > 0 ? holding.totalCost / holding.totalGrams : 0
        }
        holding.totalFeesPaid += fees
    }
}