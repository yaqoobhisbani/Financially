import Foundation
import SwiftData

// MARK: - Net Worth

@Observable
final class NetWorthViewModel {
    private let modelContext: ModelContext

    private var allTransactions: [Transaction] { (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? [] }
    private var accounts: [Account] { (try? modelContext.fetch(FetchDescriptor<Account>())) ?? [] }
    private var debtors: [Debtor] { (try? modelContext.fetch(FetchDescriptor<Debtor>())) ?? [] }
    private var creditors: [Creditor] { (try? modelContext.fetch(FetchDescriptor<Creditor>())) ?? [] }
    private var commodityHoldings: [CommodityHolding] {
        (try? modelContext.fetch(FetchDescriptor<CommodityHolding>())) ?? []
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    struct NetWorthPoint: Identifiable {
        let id = UUID()
        let date: Date
        let netWorth: Decimal
        let assets: Decimal
        let liabilities: Decimal
        let receivables: Decimal
    }

    func dataPoints(from startDate: Date, to endDate: Date) -> [NetWorthPoint] {
        let calendar = Calendar.current
        var points: [NetWorthPoint] = []
        let currentCommodityValue = commodityHoldings.filter { $0.totalGrams > 0 }
            .reduce(0) { $0 + $1.currentValue }
        let allEntries = (try? modelContext.fetch(FetchDescriptor<LedgerEntry>())) ?? []
        let allTxs = allTransactions
        var current = startDate

        while current <= endDate {
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: current) ?? current

            let totalAssets = accounts.filter { $0.isActive }.reduce(0) { sum, acct in
                sum + balanceForAccount(acct, at: monthEnd, entries: allEntries)
            } + currentCommodityValue

            let totalReceivables = debtors.reduce(0) { sum, debtor in
                sum + outstanding(debtor.id, type: .loanGiven, repayType: .loanRepayment, at: monthEnd, txs: allTxs)
            }

            let totalLiabilities = creditors.reduce(0) { sum, creditor in
                sum + outstanding(creditor.id, type: .liabilityReceived, repayType: .liabilityPayback, at: monthEnd, txs: allTxs)
            }

            points.append(NetWorthPoint(
                date: current,
                netWorth: totalAssets - totalLiabilities + totalReceivables,
                assets: totalAssets,
                liabilities: totalLiabilities,
                receivables: totalReceivables
            ))
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
        }
        return points
    }

    private func balanceForAccount(_ account: Account, at date: Date, entries: [LedgerEntry]) -> Decimal {
        let filtered = entries.filter { $0.accountId == account.id && $0.date <= date }
            .sorted { $0.date > $1.date }
        return filtered.first?.runningBalance ?? account.initialBalance
    }

    private func outstanding(_ entityId: UUID, type: TransactionType, repayType: TransactionType, at date: Date, txs: [Transaction]) -> Decimal {
        let filtered = txs.filter { $0.relatedEntityId == entityId && $0.date <= date }
        let given = filtered.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
        let repaid = filtered.filter { $0.type == repayType }.reduce(0) { $0 + $1.amount }
        return given - repaid
    }
}

// MARK: - Transaction History

@Observable
final class TransactionHistoryReportViewModel {
    private let modelContext: ModelContext

    private var allTransactions: [Transaction] {
        (try? modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func filteredTransactions(searchText: String, startDate: Date, endDate: Date, selectedType: TransactionType?) -> [Transaction] {
        var result = allTransactions
        result = result.filter { $0.date >= startDate && $0.date <= endDate.endOfDay }
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                ($0.desc ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.category ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
}

// MARK: - Monthly Summary

@Observable
final class MonthlySummaryReportViewModel {
    private let modelContext: ModelContext

    private var allTransactions: [Transaction] {
        (try? modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func transactions(for month: Date) -> [Transaction] {
        allTransactions.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func income(_ txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    func expense(_ txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func expenseByCategory(_ txs: [Transaction]) -> [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: txs.filter { $0.type == .expense }) { $0.category ?? "Other" }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.total > $1.total }
    }
}

// MARK: - Expense / Income (shared)

@Observable
final class ExpenseIncomeReportViewModel {
    private let modelContext: ModelContext

    private var allTransactions: [Transaction] {
        (try? modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func filtered(type: TransactionType, startDate: Date, endDate: Date) -> [Transaction] {
        allTransactions.filter { $0.type == type && $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    func total(_ transactions: [Transaction]) -> Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }

    func byCategory(_ transactions: [Transaction]) -> [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: transactions) { $0.category ?? "Other" }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }
}

// MARK: - Investment Report

@Observable
final class InvestmentReportViewModel {
    private let modelContext: ModelContext

    private var accounts: [Account] { (try? modelContext.fetch(FetchDescriptor<Account>())) ?? [] }
    private var investmentEntries: [InvestmentEntry] {
        (try? modelContext.fetch(FetchDescriptor<InvestmentEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var investmentAccounts: [Account] {
        accounts.filter { $0.accountType == .psx }
    }

    func entries(for account: Account, startDate: Date, endDate: Date) -> [InvestmentEntry] {
        investmentEntries.filter { $0.investmentAccountId == account.id && $0.date >= startDate && $0.date <= endDate.endOfDay }
    }
}