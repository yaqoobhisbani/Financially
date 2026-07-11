import Testing
import Foundation
@testable import Financially

@MainActor
@Suite("TradeService weighted average (Decimal quantities)")
struct TradeServiceDecimalTests {

    @Test func firstBuyEstablishesAverageCost() {
        let result = TradeService.weightedAverageBuy(
            currentQuantity: 0, currentCost: 0, currentFees: 0,
            addedQuantity: 10, addedCost: 1000, addedFees: 20
        )
        #expect(result.quantity == 10)
        #expect(result.cost == 1000)
        #expect(result.fees == 20)
        #expect(result.avgCost == 100)
    }

    @Test func secondBuyBlendsIntoWeightedAverage() {
        // Own 10g @ 100/g, buy 10g more @ 200/g -> avg should be 150/g
        let result = TradeService.weightedAverageBuy(
            currentQuantity: 10, currentCost: 1000, currentFees: 20,
            addedQuantity: 10, addedCost: 2000, addedFees: 30
        )
        #expect(result.quantity == 20)
        #expect(result.cost == 3000)
        #expect(result.fees == 50)
        #expect(result.avgCost == 150)
    }

    @Test func partialSellPreservesAverageCostOfRemainder() {
        // Own 20g @ avg 150 (cost 3000), sell 5g -> remaining cost should shrink proportionally, avg unchanged
        let result = TradeService.weightedAverageSell(
            currentQuantity: 20, currentCost: 3000, currentFees: 50,
            soldQuantity: 5
        )
        #expect(result.quantity == 15)
        #expect(result.cost == 2250)
        #expect(result.avgCost == 150)
        #expect(result.fees == 50) // fees preserved on partial sell
    }

    @Test func fullSellOutZeroesEverythingIncludingFees() {
        // Regression: fees must not leak into the next buy-in cycle after a full close-out.
        let result = TradeService.weightedAverageSell(
            currentQuantity: 15, currentCost: 2250, currentFees: 50,
            soldQuantity: 15
        )
        #expect(result.quantity == 0)
        #expect(result.cost == 0)
        #expect(result.fees == 0)
        #expect(result.avgCost == 0)
    }

    @Test func sellingMoreThanHeldAlsoZeroesOut() {
        let result = TradeService.weightedAverageSell(
            currentQuantity: 10, currentCost: 1000, currentFees: 10,
            soldQuantity: 20
        )
        #expect(result.quantity == 0)
        #expect(result.cost == 0)
        #expect(result.fees == 0)
    }

    @Test func avgCostIsZeroWhenNoQuantityHeld() {
        let result = TradeService.weightedAverageBuy(
            currentQuantity: 0, currentCost: 0, currentFees: 0,
            addedQuantity: 0, addedCost: 0, addedFees: 0
        )
        #expect(result.avgCost == 0)
    }
}

@MainActor
@Suite("TradeService weighted average (Int quantities)")
struct TradeServiceIntTests {

    @Test func buyIntEstablishesAverageCost() {
        let result = TradeService.weightedAverageBuyInt(
            currentQuantity: 0, currentCost: 0, currentFees: 0,
            addedQuantity: 100, addedCost: 5000, addedFees: 25
        )
        #expect(result.quantity == 100)
        #expect(result.avgCost == 50)
    }

    @Test func secondBuyIntBlendsWeightedAverage() {
        let result = TradeService.weightedAverageBuyInt(
            currentQuantity: 100, currentCost: 5000, currentFees: 25,
            addedQuantity: 100, addedCost: 7000, addedFees: 25
        )
        #expect(result.quantity == 200)
        #expect(result.cost == 12000)
        #expect(result.avgCost == 60)
    }

    @Test func partialSellIntPreservesAverageCost() {
        let result = TradeService.weightedAverageSellInt(
            currentQuantity: 200, currentCost: 12000, currentFees: 50,
            soldQuantity: 50
        )
        #expect(result.quantity == 150)
        #expect(result.cost == 9000)
        #expect(result.avgCost == 60)
    }

    @Test func fullSellIntZeroesFees() {
        let result = TradeService.weightedAverageSellInt(
            currentQuantity: 150, currentCost: 9000, currentFees: 50,
            soldQuantity: 150
        )
        #expect(result.quantity == 0)
        #expect(result.cost == 0)
        #expect(result.fees == 0)
    }
}

@MainActor
@Suite("TradeService holding recalculation from trade history")
struct TradeServiceRecalculateTests {

    @Test func recalculateStockHoldingReplaysBuysAndSellsInDateOrder() {
        let holdingId = UUID()
        let accountId = UUID()
        let buy1 = StockTrade(accountId: accountId, holdingId: holdingId, type: .buy, ticker: "T", companyName: "T", shares: 10, pricePerShare: 100, totalAmount: 1000, netAmount: 1000, date: Date(timeIntervalSince1970: 100))
        let buy2 = StockTrade(accountId: accountId, holdingId: holdingId, type: .buy, ticker: "T", companyName: "T", shares: 10, pricePerShare: 200, totalAmount: 2000, netAmount: 2000, date: Date(timeIntervalSince1970: 200))
        let sell1 = StockTrade(accountId: accountId, holdingId: holdingId, type: .sell, ticker: "T", companyName: "T", shares: 5, pricePerShare: 180, totalAmount: 900, netAmount: 900, date: Date(timeIntervalSince1970: 300))

        // Deliberately out of order to prove the function sorts by date before replaying.
        let result = TradeService.recalculateStockHolding(trades: [sell1, buy2, buy1])

        #expect(result.totalShares == 15)
        #expect(result.totalCost == 2250) // 3000 total cost - 5 shares sold at avg 150
        #expect(result.avgCostPerShare == 150)
    }

    @Test func recalculateStockHoldingWithNoTradesIsEmpty() {
        let result = TradeService.recalculateStockHolding(trades: [])
        #expect(result.totalShares == 0)
        #expect(result.totalCost == 0)
        #expect(result.avgCostPerShare == 0)
    }

    @Test func recalculateCommodityHoldingHandlesFullCloseOutThenReBuy() {
        let holdingId = UUID()
        let buy1 = CommodityTrade(holdingId: holdingId, type: .buy, commodityName: "Gold", symbol: "XAU", grams: 10, pricePerGram: 100, totalAmount: 1000, brokerageFee: 20, netAmount: 1020, date: Date(timeIntervalSince1970: 100))
        let sellAll = CommodityTrade(holdingId: holdingId, type: .sell, commodityName: "Gold", symbol: "XAU", grams: 10, pricePerGram: 150, totalAmount: 1500, netAmount: 1500, date: Date(timeIntervalSince1970: 200))
        let buy2 = CommodityTrade(holdingId: holdingId, type: .buy, commodityName: "Gold", symbol: "XAU", grams: 5, pricePerGram: 160, totalAmount: 800, brokerageFee: 10, netAmount: 810, date: Date(timeIntervalSince1970: 300))

        let result = TradeService.recalculateCommodityHolding(trades: [buy1, sellAll, buy2])

        #expect(result.totalGrams == 5)
        #expect(result.totalCost == 800)
        // fees from the closed-out position (20) must not leak into the new position (only 10 from buy2)
        #expect(result.totalFeesPaid == 10)
        #expect(result.avgCostPerGram == 160)
    }

    @Test func recalculateMFHoldingComputesAverageNav() {
        let holdingId = UUID()
        let accountId = UUID()
        let buy1 = MutualFundTrade(accountId: accountId, holdingId: holdingId, type: .buy, fundCode: "F", schemeName: "Fund", units: 100, navPrice: 10, totalAmount: 1000, netAmount: 1000, date: Date(timeIntervalSince1970: 100))
        let buy2 = MutualFundTrade(accountId: accountId, holdingId: holdingId, type: .buy, fundCode: "F", schemeName: "Fund", units: 100, navPrice: 12, totalAmount: 1200, netAmount: 1200, date: Date(timeIntervalSince1970: 200))

        let result = TradeService.recalculateMFHolding(trades: [buy1, buy2])

        #expect(result.totalUnits == 200)
        #expect(result.totalCost == 2200)
        #expect(result.avgNavPrice == 11)
    }
}
