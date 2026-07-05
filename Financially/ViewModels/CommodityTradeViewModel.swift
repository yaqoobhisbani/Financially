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

    private func symbol(for commodityName: String) -> String {
        commodityName.localizedCaseInsensitiveContains("gold") ? "XAU" : "XAG"
    }

    private func findOrCreateHolding(commodityName: String, currentPricePerGram: Decimal) -> CommodityHolding {
        let sym = symbol(for: commodityName)
        if let existing = holdings.first(where: { $0.symbol == sym }) {
            return existing
        }
        let holding = CommodityHolding(commodityName: commodityName, symbol: sym, currentPricePerGram: currentPricePerGram)
        modelContext.insert(holding)
        return holding
    }

    func buy(symbol: String, commodityName: String, grams: Decimal, pricePerGram: Decimal, brokerageFee: Decimal, tax: Decimal, netAmount: Decimal, date: Date, notes: String?) {
        let holding = findOrCreateHolding(commodityName: commodityName, currentPricePerGram: pricePerGram)
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

        let update = TradeService.weightedAverageBuy(
            currentQuantity: holding.totalGrams,
            currentCost: holding.totalCost,
            currentFees: holding.totalFeesPaid,
            addedQuantity: grams,
            addedCost: total,
            addedFees: fees
        )
        holding.totalGrams = update.quantity
        holding.totalCost = update.cost
        holding.totalFeesPaid = update.fees
        holding.avgCostPerGram = update.avgCost
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

        let update = TradeService.weightedAverageSell(
            currentQuantity: holding.totalGrams,
            currentCost: holding.totalCost,
            currentFees: holding.totalFeesPaid,
            soldQuantity: grams
        )
        holding.totalGrams = update.quantity
        holding.totalCost = update.cost
        holding.totalFeesPaid = update.fees
        holding.avgCostPerGram = update.avgCost
    }
}