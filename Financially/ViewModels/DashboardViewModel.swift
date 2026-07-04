import Foundation
import SwiftData

@Observable
final class DashboardViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Summary Computed

    var netWorth: Decimal {
        totalOwnFunds + totalReceivables - totalLiabilities
    }

    var totalOwnFunds: Decimal {
        totalBankBalances + totalCashBalances + totalInvestmentValues
    }

    var totalLiabilities: Decimal {
        totalCreditorOutstanding
    }

    var totalReceivables: Decimal {
        totalDebtorOutstanding
    }

    var monthlyIncome: Decimal {
        incomeThisMonth
    }

    var monthlyExpense: Decimal {
        expenseThisMonth
    }

    // MARK: - Helpers

    private var allHoldings: [StockHolding] {
        (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? []
    }

    var accounts: [Account] {
        (try? modelContext.fetch(FetchDescriptor<Account>())) ?? []
    }

    private var allTransactions: [Transaction] {
        (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
    }

    private var allDebtors: [Debtor] {
        (try? modelContext.fetch(FetchDescriptor<Debtor>())) ?? []
    }

    private var allCreditors: [Creditor] {
        (try? modelContext.fetch(FetchDescriptor<Creditor>())) ?? []
    }

    private var allCommodityHoldings: [CommodityHolding] {
        (try? modelContext.fetch(FetchDescriptor<CommodityHolding>())) ?? []
    }

    private var totalBankBalances: Decimal {
        accounts.filter { $0.accountType == .bank && $0.isActive }
            .reduce(0) { $0 + $1.currentBalance }
    }

    private var totalCashBalances: Decimal {
        accounts.filter { $0.accountType == .cash && $0.isActive }
            .reduce(0) { $0 + $1.currentBalance }
    }

    private var totalInvestmentValues: Decimal {
        let psxValue = accounts.filter { $0.accountType == .psx }
            .reduce(0) { $0 + $1.currentValue }
        let commodityValue = allCommodityHoldings.filter { $0.totalGrams > 0 }
            .reduce(0) { $0 + $1.currentValue }
        return psxValue + commodityValue
    }

    private var totalDebtorOutstanding: Decimal {
        allDebtors.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var totalCreditorOutstanding: Decimal {
        allCreditors.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var incomeThisMonth: Decimal {
        allTransactions.filter { $0.type == .income && $0.date.isInCurrentMonth }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseThisMonth: Decimal {
        allTransactions.filter { $0.type == .expense && $0.date.isInCurrentMonth }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Charts

    struct ExpenseBreakdown: Identifiable {
        let id = UUID()
        let category: String
        let total: Decimal
    }

    var expenseByCategory: [ExpenseBreakdown] {
        let grouped = Dictionary(grouping: allTransactions.filter { $0.type == .expense && $0.date.isInCurrentMonth }) { $0.category ?? "Other" }
        return grouped.map { ExpenseBreakdown(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    struct MonthlyComparison: Identifiable {
        let id = UUID()
        let month: Date
        let income: Decimal
        let expense: Decimal
    }

    var lastSixMonths: [MonthlyComparison] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { monthsAgo in
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.date(byAdding: .month, value: -monthsAgo, to: now)!))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let monthlyTxs = allTransactions.filter { $0.date >= monthStart && $0.date <= monthEnd }
            let income = monthlyTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthlyTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return MonthlyComparison(month: monthStart, income: income, expense: expense)
        }
    }

    var recentTransactions: [Transaction] {
        allTransactions.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    var activeLoanCount: Int {
        allDebtors.filter { !$0.isSettled }.count
    }

    var activeLiabilityCount: Int {
        allCreditors.filter { !$0.isSettled }.count
    }

    var activeLoanTotal: Decimal {
        allDebtors.filter { !$0.isSettled }.reduce(0) { $0 + $1.outstandingBalance }
    }

    var activeLiabilityTotal: Decimal {
        allCreditors.filter { !$0.isSettled }.reduce(0) { $0 + $1.outstandingBalance }
    }

    var activeCommodityHoldings: [CommodityHolding] {
        allCommodityHoldings.filter { $0.totalGrams > 0 }
    }

    func psxPortfolioValue(_ account: Account) -> Decimal {
        allHoldings.filter { $0.accountId == account.id }.reduce(0) { $0 + $1.currentValue }
    }

    func psxTotalCost(_ account: Account) -> Decimal {
        allHoldings.filter { $0.accountId == account.id }.reduce(0) { $0 + $1.totalCost }
    }

    func psxProfitLoss(_ accountId: UUID) -> Decimal {
        let holdings = allHoldings.filter { $0.accountId == accountId }
        return holdings.reduce(0) { $0 + $1.currentValue } - holdings.reduce(0) { $0 + $1.totalCost }
    }
}