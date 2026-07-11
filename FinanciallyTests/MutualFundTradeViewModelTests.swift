import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("MutualFundTradeViewModel")
struct MutualFundTradeViewModelTests {

    private func makeScheme(nav: Decimal = 10) -> MutualFundScheme {
        MutualFundScheme(schemeName: "Fund A", fundCode: "FA", navPrice: nav)
    }

    private func fetchHoldings(_ context: ModelContext) -> [MutualFundHolding] {
        (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
    }

    @Test func investDeductsFromBankAndCreatesHolding() {
        let context = TestSupport.makeContext()
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 5000)
        let mfAccount = TestSupport.makeAccount(in: context, name: "MF", type: .mutualFund)
        let scheme = makeScheme()
        let vm = MutualFundTradeViewModel(modelContext: context, account: mfAccount, schemeList: [scheme], holdings: [])

        vm.invest(bankAccount: bank, scheme: scheme, units: 100, navPrice: 10, fees: 25, date: Date(), notes: nil)

        #expect(bank.currentBalance == 3975) // 5000 - (100*10 + 25)
        let holding = fetchHoldings(context).first
        #expect(holding?.totalUnits == 100)
        #expect(holding?.totalCost == 1000)
        #expect(mfAccount.investedAmount == 1000)
    }

    @Test func investWithoutBankAccountLeavesCashUntouched() {
        let context = TestSupport.makeContext()
        let mfAccount = TestSupport.makeAccount(in: context, name: "MF", type: .mutualFund)
        let scheme = makeScheme()
        let vm = MutualFundTradeViewModel(modelContext: context, account: mfAccount, schemeList: [scheme], holdings: [])

        vm.invest(bankAccount: nil, scheme: scheme, units: 50, navPrice: 10, fees: 0, date: Date(), notes: nil)

        #expect(fetchHoldings(context).first?.totalUnits == 50)
    }

    @Test func redeemCreditsBankAndReducesHolding() {
        let context = TestSupport.makeContext()
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 5000)
        let mfAccount = TestSupport.makeAccount(in: context, name: "MF", type: .mutualFund)
        let scheme = makeScheme()
        let vm = MutualFundTradeViewModel(modelContext: context, account: mfAccount, schemeList: [scheme], holdings: [])
        vm.invest(bankAccount: bank, scheme: scheme, units: 100, navPrice: 10, fees: 0, date: Date(), notes: nil)
        let holding = fetchHoldings(context).first!

        vm.redeem(holding: holding, units: 40, navPrice: 12, fees: 10, bankAccount: bank, date: Date(), notes: nil)

        #expect(bank.currentBalance == 4470) // 4000 after invest + (40*12 - 10)
        #expect(holding.totalUnits == 60)
        #expect(holding.totalCost == 600)
        #expect(mfAccount.investedAmount == 600)
    }

    @Test func findOrCreateHoldingScopesByAccountAndFundCode() {
        let context = TestSupport.makeContext()
        let mfAccount1 = TestSupport.makeAccount(in: context, name: "MF1", type: .mutualFund)
        let mfAccount2 = TestSupport.makeAccount(in: context, name: "MF2", type: .mutualFund)
        let scheme = makeScheme()
        let vm1 = MutualFundTradeViewModel(modelContext: context, account: mfAccount1, schemeList: [scheme], holdings: [])
        vm1.invest(bankAccount: nil, scheme: scheme, units: 10, navPrice: 10, fees: 0, date: Date(), notes: nil)

        let vm2 = MutualFundTradeViewModel(modelContext: context, account: mfAccount2, schemeList: [scheme], holdings: fetchHoldings(context))
        vm2.invest(bankAccount: nil, scheme: scheme, units: 20, navPrice: 10, fees: 0, date: Date(), notes: nil)

        // Same fund code but different accounts must produce two separate holdings.
        let holdings = fetchHoldings(context)
        #expect(holdings.count == 2)
        #expect(Set(holdings.map(\.accountId)) == [mfAccount1.id, mfAccount2.id])
    }
}
