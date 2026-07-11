import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("LedgerService.execute")
struct LedgerServiceTests {

    private func makeService(_ context: ModelContext) -> LedgerService {
        LedgerService(modelContext: context)
    }

    private func ledgerEntries(for transaction: Transaction, in context: ModelContext) -> [LedgerEntry] {
        let txnId = transaction.id
        return (try? context.fetch(FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.transactionId == txnId }))) ?? []
    }

    // MARK: - Expense / Income

    @Test func expenseDebitsSourceAndCreatesOneEntry() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = makeService(context)

        let tx = try service.execute(TransactionRequest(type: .expense, amount: 300, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 700)
        let entries = ledgerEntries(for: tx, in: context)
        #expect(entries.count == 1)
        #expect(entries.first?.entryType == .debit)
        #expect(entries.first?.runningBalance == 700)
    }

    @Test func expenseWithNoAccountCreatesTransactionButNoEntry() throws {
        let context = TestSupport.makeContext()
        let service = makeService(context)

        let tx = try service.execute(TransactionRequest(type: .expense, amount: 300, date: Date(), sourceAccountId: nil))

        #expect(ledgerEntries(for: tx, in: context).isEmpty)
    }

    @Test func incomeCreditsAccountAndCreatesOneEntry() throws {
        let context = TestSupport.makeContext()
        let dest = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 500)
        let service = makeService(context)

        let tx = try service.execute(TransactionRequest(type: .income, amount: 1000, date: Date(), sourceAccountId: dest.id))

        #expect(dest.currentBalance == 1500)
        let entries = ledgerEntries(for: tx, in: context)
        #expect(entries.count == 1)
        #expect(entries.first?.entryType == .credit)
    }

    // MARK: - Transfer

    @Test func transferMovesMoneyBetweenAccountsWithTwoEntries() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let dest = TestSupport.makeAccount(in: context, name: "Cash", type: .cash, initialBalance: 100)
        let service = makeService(context)

        let tx = try service.execute(TransactionRequest(type: .transfer, amount: 400, date: Date(), sourceAccountId: source.id, destinationAccountId: dest.id))

        #expect(source.currentBalance == 600)
        #expect(dest.currentBalance == 500)
        #expect(ledgerEntries(for: tx, in: context).count == 2)
    }

    // MARK: - Investment add capital / withdrawal

    @Test func investmentAddCapitalMovesFromBankIntoPSXAccount() throws {
        let context = TestSupport.makeContext()
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .investmentAddCapital, amount: 600, date: Date(), sourceAccountId: bank.id, destinationAccountId: psx.id))

        #expect(bank.currentBalance == 400)
        #expect(psx.currentBalance == 600)
    }

    @Test func investmentAddCapitalWithoutSourceCreditsDestinationOnly() throws {
        let context = TestSupport.makeContext()
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .investmentAddCapital, amount: 600, date: Date(), destinationAccountId: psx.id))

        #expect(psx.currentBalance == 600)
    }

    @Test func investmentWithdrawalMovesFromPSXToBank() throws {
        let context = TestSupport.makeContext()
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx, initialBalance: 1000)
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .investmentWithdrawal, amount: 400, date: Date(), sourceAccountId: psx.id, destinationAccountId: bank.id))

        #expect(psx.currentBalance == 600)
        #expect(bank.currentBalance == 400)
    }

    // MARK: - Loans / Liabilities

    @Test func loanGivenDebitsSourceOnly() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .loanGiven, amount: 300, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 700)
    }

    @Test func loanRepaymentCreditsDestination() throws {
        let context = TestSupport.makeContext()
        let dest = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .loanRepayment, amount: 250, date: Date(), destinationAccountId: dest.id))

        #expect(dest.currentBalance == 250)
    }

    @Test func liabilityReceivedCreditsDestination() throws {
        let context = TestSupport.makeContext()
        let dest = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .liabilityReceived, amount: 500, date: Date(), destinationAccountId: dest.id))

        #expect(dest.currentBalance == 500)
    }

    @Test func liabilityPaybackDebitsSource() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 500)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .liabilityPayback, amount: 200, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 300)
    }

    // MARK: - Investment profit/loss

    @Test func investmentProfitLossAdjustsTotalProfitLossNotBalance() throws {
        let context = TestSupport.makeContext()
        let psx = TestSupport.makeAccount(in: context, name: "PSX", type: .psx, initialBalance: 1000)
        psx.totalProfitLoss = 100
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .investmentProfitLoss, amount: 50, date: Date(), sourceAccountId: psx.id))

        #expect(psx.totalProfitLoss == 150)
        #expect(psx.currentBalance == 1000) // unaffected
    }

    // MARK: - Committees

    @Test func committeeContributionDebitsSource() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .committeeContribution, amount: 100, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 900)
    }

    @Test func committeePayoutCreditsDestination() throws {
        let context = TestSupport.makeContext()
        let dest = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .committeePayout, amount: 1000, date: Date(), destinationAccountId: dest.id))

        #expect(dest.currentBalance == 1000)
    }

    // MARK: - Commodities

    @Test func commodityBuyDebitsSource() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .commodityBuy, amount: 400, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 600)
    }

    @Test func commoditySellCreditsSourceAccount() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let service = makeService(context)

        try service.execute(TransactionRequest(type: .commoditySell, amount: 500, date: Date(), sourceAccountId: source.id))

        #expect(source.currentBalance == 500)
    }

    // MARK: - Stock/MF trade types are handled outside LedgerService

    @Test func stockAndMutualFundTradeTypesDoNotMutateBalances() throws {
        let context = TestSupport.makeContext()
        // Bank/cash satisfies every one of these types' validation constraints (mutualFundBuy needs a
        // bank/cash source, mutualFundSell needs a bank/cash destination, stock types have none).
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = makeService(context)

        for type: TransactionType in [.stockBuy, .stockSell, .mutualFundBuy, .mutualFundSell] {
            try service.execute(TransactionRequest(type: type, amount: 100, date: Date(), sourceAccountId: account.id, destinationAccountId: account.id))
        }

        #expect(account.currentBalance == 1000)
    }

    // MARK: - Errors

    @Test func throwsWhenSourceAccountNotFound() {
        let context = TestSupport.makeContext()
        let service = makeService(context)
        #expect(throws: ValidationError.self) {
            try service.execute(TransactionRequest(type: .expense, amount: 100, date: Date(), sourceAccountId: UUID()))
        }
    }

    @Test func throwsWhenValidationFails() {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10)
        let service = makeService(context)
        #expect(throws: ValidationError.self) {
            try service.execute(TransactionRequest(type: .expense, amount: 1000, date: Date(), sourceAccountId: source.id))
        }
    }
}
