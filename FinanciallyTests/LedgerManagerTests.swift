import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("LedgerManager.deleteTransaction — plain cash transactions")
struct LedgerManagerCashReversalTests {

    @Test func deletingExpenseRestoresBalanceAndRemovesEntry() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .expense, amount: 300, date: Date(), sourceAccountId: account.id))
        #expect(account.currentBalance == 700)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(account.currentBalance == 1000)
        let txnId = tx.id
        let remainingEntries = try context.fetch(FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.transactionId == txnId }))
        #expect(remainingEntries.isEmpty)
    }

    @Test func deletingIncomeRemovesBalanceAndEntry() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .income, amount: 500, date: Date(), sourceAccountId: account.id))
        #expect(account.currentBalance == 1500)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(account.currentBalance == 1000)
        let txnId = tx.id
        let remainingEntries = try context.fetch(FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.transactionId == txnId }))
        #expect(remainingEntries.isEmpty)
    }

    @Test func deletingTransferRestoresBothBalances() throws {
        let context = TestSupport.makeContext()
        let source = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let dest = TestSupport.makeAccount(in: context, name: "Cash", type: .cash, initialBalance: 200)
        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .transfer, amount: 400, date: Date(), sourceAccountId: source.id, destinationAccountId: dest.id))
        #expect(source.currentBalance == 600)
        #expect(dest.currentBalance == 600)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(source.currentBalance == 1000)
        #expect(dest.currentBalance == 200)
    }

    @Test func deletingLoanGivenRestoresBalanceAndDebtorTotals() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let debtor = Debtor(name: "Ali", totalLent: 500, totalRepaid: 0)
        context.insert(debtor)

        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .loanGiven, amount: 500, date: Date(), sourceAccountId: account.id, relatedEntityId: debtor.id))
        debtor.totalLent += 500 // mirrors what LoanTransactionViewModel would do alongside the ledger call
        #expect(account.currentBalance == 500)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(account.currentBalance == 1000)
        #expect(debtor.totalLent == 500) // reversed back down by the amount recorded on the transaction
    }

    @Test func deletingLiabilityPaybackRestoresBalanceAndCreditorTotals() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let creditor = Creditor(name: "Sana", totalReceived: 500, totalReturned: 0)
        context.insert(creditor)

        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .liabilityPayback, amount: 200, date: Date(), sourceAccountId: account.id, relatedEntityId: creditor.id))
        creditor.totalReturned += 200
        #expect(account.currentBalance == 800)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(account.currentBalance == 1000)
        #expect(creditor.totalReturned == 0)
    }

    @Test func deletingTransactionRemovesItFromContext() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let service = LedgerService(modelContext: context)
        let tx = try service.execute(TransactionRequest(type: .expense, amount: 100, date: Date(), sourceAccountId: account.id))
        let txId = tx.id

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        let remaining = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txId }))
        #expect(remaining.isEmpty)
    }
}

@MainActor
@Suite("LedgerManager.deleteTransaction — linked trade reversal")
struct LedgerManagerTradeReversalTests {

    @Test func deletingLinkedStockBuyReversesBalanceHoldingAndAccountSync() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 10_000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])

        vm.buy(ticker: "TST", companyName: "Test Co", shares: 10, pricePerShare: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil)

        #expect(account.currentBalance == 9000)
        let holding = try #require(try context.fetch(FetchDescriptor<StockHolding>()).first)
        #expect(holding.totalShares == 10)
        #expect(account.investedAmount == 1000)

        let trade = try #require(try context.fetch(FetchDescriptor<StockTrade>()).first)
        let transactionId = try #require(trade.transactionId)
        let transaction = try #require(try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == transactionId })).first)

        try LedgerManager(modelContext: context).deleteTransaction(transaction)

        #expect(account.currentBalance == 10_000)
        #expect(holding.totalShares == 0)
        #expect(holding.totalCost == 0)
        #expect(account.investedAmount == 0)
        #expect(try context.fetch(FetchDescriptor<StockTrade>()).isEmpty)
    }

    @Test func deletingOneOfTwoStockBuysRecalculatesHoldingFromRemainder() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "AKD", type: .psx, initialBalance: 10_000)
        let vm = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [])

        vm.buy(ticker: "TST", companyName: "Test Co", shares: 10, pricePerShare: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(timeIntervalSince1970: 100), notes: nil)
        let firstHolding = try #require(try context.fetch(FetchDescriptor<StockHolding>()).first)
        let vm2 = StockTradeViewModel(modelContext: context, account: account, stockList: [], holdings: [firstHolding])
        vm2.buy(ticker: "TST", companyName: "Test Co", shares: 10, pricePerShare: 200, brokerageFee: 0, tax: 0, netAmount: 2000, date: Date(timeIntervalSince1970: 200), notes: nil)

        #expect(firstHolding.totalShares == 20)
        #expect(firstHolding.totalCost == 3000)

        let trades = try context.fetch(FetchDescriptor<StockTrade>()).sorted { $0.date < $1.date }
        let firstTrade = trades[0]
        let firstTxnId = try #require(firstTrade.transactionId)
        let firstTxn = try #require(try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == firstTxnId })).first)

        try LedgerManager(modelContext: context).deleteTransaction(firstTxn)

        // Only the second buy (10 shares @ 200) should remain.
        #expect(firstHolding.totalShares == 10)
        #expect(firstHolding.totalCost == 2000)
        #expect(account.currentBalance == 8000) // 10000 - 1000 (first buy) - 2000 (second buy) + 1000 (reversed first buy)
    }

    @Test func deletingLinkedCommodityBuyReversesCashAndHolding() throws {
        let context = TestSupport.makeContext()
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 5000)
        let ledger = LedgerService(modelContext: context)
        let tx = try ledger.execute(TransactionRequest(type: .commodityBuy, amount: 1000, date: Date(), sourceAccountId: bank.id))

        let commodityVM = CommodityTradeViewModel(modelContext: context, commodityList: [], holdings: [])
        commodityVM.buy(symbol: "XAU", commodityName: "Gold", grams: 10, pricePerGram: 100, brokerageFee: 0, tax: 0, netAmount: 1000, date: Date(), notes: nil, transactionId: tx.id)

        #expect(bank.currentBalance == 4000)
        let holding = try #require(try context.fetch(FetchDescriptor<CommodityHolding>()).first)
        #expect(holding.totalGrams == 10)

        try LedgerManager(modelContext: context).deleteTransaction(tx)

        #expect(bank.currentBalance == 5000)
        #expect(holding.totalGrams == 0)
        #expect(holding.totalCost == 0)
    }

    @Test func deletingLinkedMutualFundBuyReversesBankBalanceHoldingAndAccountSync() throws {
        let context = TestSupport.makeContext()
        let bank = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 5000)
        let mfAccount = TestSupport.makeAccount(in: context, name: "MF", type: .mutualFund)
        let scheme = MutualFundScheme(schemeName: "Fund A", fundCode: "FA", navPrice: 10)
        context.insert(scheme)

        let vm = MutualFundTradeViewModel(modelContext: context, account: mfAccount, schemeList: [scheme], holdings: [])
        vm.invest(bankAccount: bank, scheme: scheme, units: 100, navPrice: 10, fees: 0, date: Date(), notes: nil)

        #expect(bank.currentBalance == 4000)
        let holding = try #require(try context.fetch(FetchDescriptor<MutualFundHolding>()).first)
        #expect(holding.totalUnits == 100)
        #expect(mfAccount.investedAmount == 1000)

        let trade = try #require(try context.fetch(FetchDescriptor<MutualFundTrade>()).first)
        let transactionId = try #require(trade.transactionId)
        let transaction = try #require(try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == transactionId })).first)

        try LedgerManager(modelContext: context).deleteTransaction(transaction)

        #expect(bank.currentBalance == 5000)
        #expect(holding.totalUnits == 0)
        #expect(mfAccount.investedAmount == 0)
    }
}
