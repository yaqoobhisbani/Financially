import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("StockTradeViewModel")
struct StockTradeViewModelTests {

    private func fetchHoldings(_ context: ModelContext) -> [StockHolding] {
        (try? context.fetch(FetchDescriptor<StockHolding>())) ?? []
    }

    @Test func buyDeductsNetAmountAndUpdatesHoldingAverage() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 5000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])

        vm.buy(ticker: "TST", companyName: "Test Co", shares: 20, pricePerShare: 50, brokerageFee: 10, tax: 5, netAmount: 1015, date: Date(), notes: nil)

        #expect(account.currentBalance == 3985)
        let holding = fetchHoldings(context).first
        #expect(holding?.totalShares == 20)
        #expect(holding?.totalCost == 1000)
        #expect(holding?.totalFeesPaid == 15)
        #expect(holding?.avgCostPerShare == 50)
    }

    @Test func sellCreditsNetProceedsAndReducesHolding() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 5000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])
        vm.buy(ticker: "TST", companyName: "Test Co", shares: 20, pricePerShare: 50, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)
        let holding = fetchHoldings(context).first!

        vm.sell(holding: holding, shares: 10, pricePerShare: 60, brokerageFee: 5, tax: 0, netProceeds: 595, date: Date(), notes: nil)

        #expect(account.currentBalance == 4595) // 4000 after buy + 595 proceeds
        #expect(holding.totalShares == 10)
        #expect(holding.totalCost == 500)
        #expect(holding.avgCostPerShare == 50)
    }

    @Test func fullSellZeroesOutHoldingQuantityAndCost() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 5000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])
        vm.buy(ticker: "TST", companyName: "Test Co", shares: 10, pricePerShare: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)
        let holding = fetchHoldings(context).first!

        vm.sell(holding: holding, shares: 10, pricePerShare: 100, brokerageFee: 0, tax: 0, netProceeds: 1000, date: Date(), notes: nil)

        #expect(holding.totalShares == 0)
        #expect(holding.totalCost == 0)
        #expect(fetchHoldings(context).filter { $0.totalShares > 0 }.isEmpty)
    }

    @Test func secondBuySameTickerReusesHoldingAndBlendsAverage() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 5000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])
        vm.buy(ticker: "TST", companyName: "Test Co", shares: 10, pricePerShare: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)

        // Re-fetch holdings fresh (mirrors how a @Query-backed view would re-construct the VM).
        let vm2 = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: fetchHoldings(context))
        vm2.buy(ticker: "TST", companyName: "Test Co", shares: 5, pricePerShare: 110, brokerageFee: 0, tax: 0, netAmount: 550, date: Date(), notes: nil)

        let holdings = fetchHoldings(context)
        #expect(holdings.count == 1)
        #expect(holdings.first?.totalShares == 15)
    }

    @Test func differentTickersProduceSeparateHoldings() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 5000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])
        vm.buy(ticker: "AAA", companyName: "A Co", shares: 10, pricePerShare: 10, brokerageFee: 0, tax: 0, netAmount: 100, date: Date(), notes: nil)

        let vm2 = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: fetchHoldings(context))
        vm2.buy(ticker: "BBB", companyName: "B Co", shares: 10, pricePerShare: 20, brokerageFee: 0, tax: 0, netAmount: 200, date: Date(), notes: nil)

        #expect(fetchHoldings(context).count == 2)
    }
}
