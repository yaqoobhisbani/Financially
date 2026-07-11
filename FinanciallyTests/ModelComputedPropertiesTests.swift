import Testing
import Foundation
@testable import Financially

@MainActor
@Suite("StockHolding computed properties")
struct StockHoldingTests {
    @Test func currentValueUsesLivePriceWhenAvailable() {
        let holding = StockHolding(accountId: UUID(), companyName: "Test Co", ticker: "TST", totalShares: 10, totalCost: 1000, currentPrice: 120)
        #expect(holding.currentValue == 1200)
    }

    @Test func currentValueFallsBackToCostWhenNoLivePrice() {
        let holding = StockHolding(accountId: UUID(), companyName: "Test Co", ticker: "TST", totalShares: 10, totalCost: 1000, currentPrice: nil)
        #expect(holding.currentValue == 1000)
    }

    @Test func unrealizedPAndLIsCurrentValueMinusCost() {
        let holding = StockHolding(accountId: UUID(), companyName: "Test Co", ticker: "TST", totalShares: 10, totalCost: 1000, currentPrice: 150)
        #expect(holding.unrealizedPAndL == 500)
    }

    @Test func returnPercentageComputesCorrectly() {
        let holding = StockHolding(accountId: UUID(), companyName: "Test Co", ticker: "TST", totalShares: 10, totalCost: 1000, currentPrice: 110)
        #expect(holding.returnPercentage == 10)
    }

    @Test func returnPercentageIsZeroWhenNoCostBasis() {
        let holding = StockHolding(accountId: UUID(), companyName: "Test Co", ticker: "TST", totalShares: 0, totalCost: 0)
        #expect(holding.returnPercentage == 0)
    }
}

@MainActor
@Suite("CommodityHolding computed properties")
struct CommodityHoldingTests {
    @Test func currentValueUsesLivePricePerGram() {
        let holding = CommodityHolding(commodityName: "Gold", symbol: "XAU", totalGrams: 5, totalCost: 500, currentPricePerGram: 130)
        #expect(holding.currentValue == 650)
    }

    @Test func currentValueFallsBackToCostWithoutLivePrice() {
        let holding = CommodityHolding(commodityName: "Gold", symbol: "XAU", totalGrams: 5, totalCost: 500, currentPricePerGram: nil)
        #expect(holding.currentValue == 500)
    }

    @Test func unrealizedPAndLReflectsGainOrLoss() {
        let holding = CommodityHolding(commodityName: "Silver", symbol: "XAG", totalGrams: 100, totalCost: 1000, currentPricePerGram: 9)
        #expect(holding.unrealizedPAndL == -100)
    }

    @Test func returnPercentageIsZeroWithoutCost() {
        let holding = CommodityHolding(commodityName: "Silver", symbol: "XAG")
        #expect(holding.returnPercentage == 0)
    }
}

@MainActor
@Suite("MutualFundHolding computed properties")
struct MutualFundHoldingTests {
    @Test func currentValueUsesLiveNavPrice() {
        let holding = MutualFundHolding(accountId: UUID(), schemeName: "Fund A", fundCode: "FA", totalUnits: 200, totalCost: 2000, currentNavPrice: 12)
        #expect(holding.currentValue == 2400)
    }

    @Test func currentValueFallsBackToCostWithoutLiveNav() {
        let holding = MutualFundHolding(accountId: UUID(), schemeName: "Fund A", fundCode: "FA", totalUnits: 200, totalCost: 2000, currentNavPrice: nil)
        #expect(holding.currentValue == 2000)
    }

    @Test func returnPercentageComputesCorrectly() {
        let holding = MutualFundHolding(accountId: UUID(), schemeName: "Fund A", fundCode: "FA", totalUnits: 100, totalCost: 1000, currentNavPrice: 12)
        #expect(holding.returnPercentage == 20)
    }
}

@MainActor
@Suite("Debtor / Creditor outstanding balance")
struct DebtorCreditorTests {
    @Test func debtorOutstandingBalanceIsLentMinusRepaid() {
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 400)
        #expect(debtor.outstandingBalance == 600)
        #expect(!debtor.isSettled)
    }

    @Test func debtorIsSettledWhenFullyRepaid() {
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 1000)
        #expect(debtor.outstandingBalance == 0)
        #expect(debtor.isSettled)
    }

    @Test func creditorOutstandingBalanceIsReceivedMinusReturned() {
        let creditor = Creditor(name: "Sana", totalReceived: 5000, totalReturned: 2000)
        #expect(creditor.outstandingBalance == 3000)
        #expect(!creditor.isSettled)
    }

    @Test func creditorIsSettledWhenFullyReturned() {
        let creditor = Creditor(name: "Sana", totalReceived: 5000, totalReturned: 5000)
        #expect(creditor.isSettled)
    }
}

@MainActor
@Suite("Committee computed properties")
struct CommitteeTests {
    private func makeCommittee(mySlots: Int = 1, monthsCompleted: Int = 0, totalSlotsPaid: Int? = 0) -> Committee {
        let committee = Committee(name: "Family Committee", monthlyAmount: 10_000, totalMembers: 10, startMonth: Date(), mySlots: mySlots)
        committee.monthsCompleted = monthsCompleted
        committee.totalSlotsPaid = totalSlotsPaid
        return committee
    }

    @Test func totalPayoutIsMonthlyAmountTimesMembers() {
        let committee = makeCommittee()
        #expect(committee.totalPayout == 100_000)
    }

    @Test func myTotalPayoutScalesWithSlots() {
        let committee = makeCommittee(mySlots: 2)
        #expect(committee.myTotalPayout == 200_000)
    }

    @Test func isCompleteWhenAllMonthsPaid() {
        let committee = makeCommittee(monthsCompleted: 10)
        #expect(committee.isComplete)
    }

    @Test func isNotCompleteWithRemainingMonths() {
        let committee = makeCommittee(monthsCompleted: 4)
        #expect(!committee.isComplete)
        #expect(committee.remainingMonths == 6)
    }

    @Test func remainingMonthsNeverGoesNegative() {
        let committee = makeCommittee(monthsCompleted: 15)
        #expect(committee.remainingMonths == 0)
    }

    @Test func totalContributedScalesWithSlotsPaidNotMonths() {
        // Regression: totalContributed must use totalSlotsPaid, not monthsCompleted,
        // otherwise multi-slot committees under-report money actually paid in.
        let committee = makeCommittee(mySlots: 2, monthsCompleted: 3, totalSlotsPaid: 6)
        #expect(committee.totalContributed == 60_000)
    }

    @Test func slotPositionListParsesCommaSeparatedString() {
        let committee = makeCommittee()
        committee.mySlotPositions = "2, 5, 9"
        #expect(committee.slotPositionList == [2, 5, 9])
    }

    @Test func slotPositionListIsEmptyWhenNil() {
        let committee = makeCommittee()
        #expect(committee.slotPositionList.isEmpty)
    }
}

@MainActor
@Suite("Account computed properties")
struct AccountTests {
    @Test func currentValueForBankAccountIsCurrentBalance() {
        let account = Account(name: "HBL", accountType: .bank, initialBalance: 5000)
        #expect(account.currentValue == 5000)
    }

    @Test func currentValueForPSXAccountSumsBalanceInvestmentAndPAndL() {
        let account = Account(name: "AKD", accountType: .psx, investedAmount: 10_000, totalProfitLoss: 500)
        account.currentBalance = 1000
        #expect(account.currentValue == 11_500)
    }

    @Test func currentValueForMutualFundAccountExcludesCashBalance() {
        let account = Account(name: "MF", accountType: .mutualFund, investedAmount: 8000, totalProfitLoss: -200)
        account.currentBalance = 999 // should be ignored for MF accounts
        #expect(account.currentValue == 7800)
    }

    @Test func returnPercentageIsZeroWithoutInvestedAmount() {
        let account = Account(name: "Empty", accountType: .psx)
        #expect(account.returnPercentage == 0)
    }

    @Test func returnPercentageComputesFromProfitOverInvested() {
        let account = Account(name: "AKD", accountType: .psx, investedAmount: 2000, totalProfitLoss: 400)
        #expect(account.returnPercentage == 20)
    }

    @Test func syncFromHoldingsAggregatesStockHoldings() {
        let account = Account(name: "AKD", accountType: .psx)
        let h1 = StockHolding(accountId: account.id, companyName: "A", ticker: "A", totalShares: 10, totalCost: 1000, currentPrice: 120)
        let h2 = StockHolding(accountId: account.id, companyName: "B", ticker: "B", totalShares: 5, totalCost: 500, currentPrice: 90)
        account.syncFromHoldings([h1, h2])
        #expect(account.investedAmount == 1500)
        #expect(account.totalProfitLoss == 150) // (1200-1000) + (450-500)
    }

    @Test func syncFromHoldingsIsNoOpForNonPSXAccounts() {
        let account = Account(name: "Bank", accountType: .bank, investedAmount: 999, totalProfitLoss: 999)
        let h1 = StockHolding(accountId: account.id, companyName: "A", ticker: "A", totalShares: 10, totalCost: 1000)
        account.syncFromHoldings([h1])
        #expect(account.investedAmount == 999)
        #expect(account.totalProfitLoss == 999)
    }

    @Test func syncFromMFHoldingsAggregatesMutualFundHoldings() {
        let account = Account(name: "MF", accountType: .mutualFund)
        let h1 = MutualFundHolding(accountId: account.id, schemeName: "Fund A", fundCode: "FA", totalUnits: 100, totalCost: 1000, currentNavPrice: 12)
        account.syncFromMFHoldings([h1])
        #expect(account.investedAmount == 1000)
        #expect(account.totalProfitLoss == 200)
    }
}
