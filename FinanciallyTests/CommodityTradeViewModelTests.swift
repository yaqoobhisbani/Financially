import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("CommodityTradeViewModel")
struct CommodityTradeViewModelTests {

    private func fetchHoldings(_ context: ModelContext) -> [CommodityHolding] {
        (try? context.fetch(FetchDescriptor<CommodityHolding>())) ?? []
    }

    @Test func buyCreatesHoldingWithWeightedAverageCost() {
        let context = TestSupport.makeContext()
        let vm = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: [])

        vm.buy(symbol: "XAU", commodityName: "Gold", grams: 10, pricePerGram: 100, brokerageFee: 20, tax: 5, netAmount: 1025, date: Date(), notes: nil)

        let holding = fetchHoldings(context).first
        #expect(holding?.totalGrams == 10)
        #expect(holding?.totalCost == 1000)
        #expect(holding?.totalFeesPaid == 25)
        #expect(holding?.avgCostPerGram == 100)
    }

    @Test func secondBuySameCommodityBlendsIntoExistingHolding() {
        let context = TestSupport.makeContext()
        let vm = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: [])
        vm.buy(symbol: "XAU", commodityName: "Gold", grams: 10, pricePerGram: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)

        let vm2 = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: fetchHoldings(context))
        vm2.buy(symbol: "XAU", commodityName: "Gold", grams: 10, pricePerGram: 200, brokerageFee: 0, tax: 0, netAmount: 2000, date: Date(), notes: nil)

        let holdings = fetchHoldings(context)
        #expect(holdings.count == 1)
        #expect(holdings.first?.totalGrams == 20)
        #expect(holdings.first?.avgCostPerGram == 150)
    }

    @Test func sellReducesHoldingByWeightedAverageCost() {
        let context = TestSupport.makeContext()
        let vm = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: [])
        vm.buy(symbol: "XAG", commodityName: "Silver", grams: 100, pricePerGram: 10, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)
        let holding = fetchHoldings(context).first!

        vm.sell(holding: holding, grams: 40, pricePerGram: 12, brokerageFee: 0, tax: 0, netProceeds: 480, date: Date(), notes: nil)

        #expect(holding.totalGrams == 60)
        #expect(holding.totalCost == 600)
        #expect(holding.avgCostPerGram == 10)
    }

    @Test func goldAndSilverResolveToDistinctSymbols() {
        let context = TestSupport.makeContext()
        let vm = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: [])
        vm.buy(symbol: "XAU", commodityName: "Gold", grams: 1, pricePerGram: 100, brokerageFee: 0, tax: 0, netAmount: 100, date: Date(), notes: nil)

        let vm2 = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: fetchHoldings(context))
        vm2.buy(symbol: "XAG", commodityName: "Silver", grams: 1, pricePerGram: 10, brokerageFee: 0, tax: 0, netAmount: 10, date: Date(), notes: nil)

        let holdings = fetchHoldings(context)
        #expect(holdings.count == 2)
        #expect(Set(holdings.map(\.symbol)) == ["XAU", "XAG"])
    }
}
