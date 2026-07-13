import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("DashboardViewModel")
struct DashboardViewModelTests {

    @Test func totalOwnFundsSumsBankCashAndInvestments() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        TestSupport.makeAccount(in: context, name: "Cash", type: .cash, initialBalance: 500)
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx)
        psx.currentBalance = 200
        psx.investedAmount = 300
        psx.totalProfitLoss = 50
        let vm = DashboardViewModel(modelContext: context)

        // PSX currentValue = currentBalance + investedAmount + totalProfitLoss = 200+300+50 = 550
        let expected: Decimal = 2050
        #expect(vm.totalOwnFunds == expected)
    }

    @Test func inactiveAccountsAreExcludedFromTotals() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        TestSupport.makeAccount(in: context, name: "Closed", type: .bank, initialBalance: 5000, isActive: false)
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.totalAccounts == 1000)
    }

    @Test func netWorthCombinesFundsReceivablesAndLiabilities() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10_000)
        let debtor = Debtor(name: "Ali", totalLent: 2000, totalRepaid: 500) // 1500 receivable
        context.insert(debtor)
        let creditor = Creditor(name: "Sana", totalReceived: 3000, totalReturned: 1000) // 2000 owed
        context.insert(creditor)
        let vm = DashboardViewModel(modelContext: context)

        // netWorth = ownFunds(10000) + receivables(1500) - liabilities(2000)
        #expect(vm.netWorth == 9500)
    }

    @Test func totalCommitteeReceivableUsesMySlotsScaledPayout() {
        // Regression: multi-slot committees must scale the receivable by mySlots.
        let context = TestSupport.makeContext()
        let committee = Committee(name: "Family", monthlyAmount: 1000, totalMembers: 10, startMonth: Date(), mySlots: 2)
        context.insert(committee) // myTotalPayout = 20,000, nothing received yet
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.totalCommitteeReceivable == 20_000)
    }

    @Test func totalCommitteeReceivableSubtractsAmountsAlreadyPaidOut() {
        let context = TestSupport.makeContext()
        let committee = Committee(name: "Family", monthlyAmount: 1000, totalMembers: 10, startMonth: Date())
        context.insert(committee) // myTotalPayout = 10,000
        let payout = CommitteePayout(committeeId: committee.id, month: Date(), amount: 4000, destinationAccountId: UUID())
        context.insert(payout)
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.totalCommitteeReceivable == 6000)
    }

    @Test func activeLoanTotalOnlyCountsUnsettledDebtors() {
        let context = TestSupport.makeContext()
        context.insert(Debtor(name: "Settled", totalLent: 1000, totalRepaid: 1000))
        context.insert(Debtor(name: "Owing", totalLent: 500, totalRepaid: 100))
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.activeLoanCount == 1)
        #expect(vm.activeLoanTotal == 400)
    }

    @Test func activeLiabilityTotalOnlyCountsUnsettledCreditors() {
        let context = TestSupport.makeContext()
        context.insert(Creditor(name: "Settled", totalReceived: 1000, totalReturned: 1000))
        context.insert(Creditor(name: "Owed", totalReceived: 800, totalReturned: 300))
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.activeLiabilityCount == 1)
        #expect(vm.activeLiabilityTotal == 500)
    }

    @Test func hasNoDataIsTrueForEmptyDataset() {
        let context = TestSupport.makeContext()
        let vm = DashboardViewModel(modelContext: context)
        #expect(vm.hasNoData)
    }

    @Test func hasNoDataIsFalseOnceAnAccountExists() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank)
        let vm = DashboardViewModel(modelContext: context)
        #expect(!vm.hasNoData)
    }

    @Test func assetAllocationOmitsZeroValueSlicesAndSortsDescending() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 300)
        TestSupport.makeAccount(in: context, name: "Cash", type: .cash, initialBalance: 700)
        let vm = DashboardViewModel(modelContext: context)

        let slices = vm.assetAllocation
        #expect(slices.map(\.label) == ["Cash", "Banks"]) // descending by value, PSX/Commodity/etc omitted (zero)
    }

    @Test func totalUnrealizedPLAggregatesAcrossPortfolio() {
        let context = TestSupport.makeContext()
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx)
        psx.investedAmount = 300
        psx.totalProfitLoss = 50
        let gold = CommodityHolding(commodityName: "Gold", symbol: "XAU", totalGrams: 10, totalCost: 1000, currentPricePerGram: 120)
        context.insert(gold) // currentValue 1200, unrealizedPAndL 200
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.totalUnrealizedPL == 250) // 50 (PSX) + 200 (gold)
        // cost basis = investedAmount(300) + totalCost(1000) = 1300
        #expect(vm.totalReturnPercentage == (Decimal(250) / Decimal(1300)) * 100)
    }

    @Test func totalReturnPercentageIsZeroWithoutCostBasis() {
        let context = TestSupport.makeContext()
        TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let vm = DashboardViewModel(modelContext: context)

        #expect(vm.totalUnrealizedPL == 0)
        #expect(vm.totalReturnPercentage == 0)
    }

    @Test func incomeByCategoryGroupsAndRelabelsInflows() {
        let context = TestSupport.makeContext()
        let now = Date()
        context.insert(Transaction(type: .income, amount: 1000, date: now, category: "Salary"))
        context.insert(Transaction(type: .income, amount: 200, date: now, category: "Salary"))
        context.insert(Transaction(type: .commoditySell, amount: 500, date: now))
        let vm = DashboardViewModel(modelContext: context)

        let breakdown = vm.incomeByCategory
        #expect(breakdown.count == 2)
        #expect(breakdown.first?.category == "Salary") // 1200, sorted descending
        #expect(breakdown.first?.total == 1200)
        #expect(breakdown.contains { $0.category == "Commodity" && $0.total == 500 })
    }

    @Test func psxProfitLossIsCurrentValueMinusTotalCostAcrossHoldings() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "PSX", type: .psx)
        let h1 = StockHolding(accountId: account.id, companyName: "A", ticker: "A", totalShares: 10, totalCost: 1000, currentPrice: 120)
        let h2 = StockHolding(accountId: account.id, companyName: "B", ticker: "B", totalShares: 5, totalCost: 500, currentPrice: 80)
        context.insert(h1)
        context.insert(h2)
        let vm = DashboardViewModel(modelContext: context)

        // (1200-1000) + (400-500) = 100
        #expect(vm.psxProfitLoss(account.id) == 100)
    }
}
