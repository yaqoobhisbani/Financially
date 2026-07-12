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

    var totalAccounts: Decimal {
        totalBankBalances + totalCashBalances
    }

    var totalInvested: Decimal {
        totalInvestmentValues
    }

    var totalLiabilities: Decimal {
        totalCreditorOutstanding
    }

    var totalReceivables: Decimal {
        totalDebtorOutstanding + totalCommitteeReceivable
    }

    var monthlyIncome: Decimal {
        incomeThisMonth
    }

    var monthlyExpense: Decimal {
        expenseThisMonth
    }

    /// Net cash flow this month (income minus expense) — the hero's "this month" delta.
    var netFlowThisMonth: Decimal {
        monthlyIncome - monthlyExpense
    }

    /// This month's net cash flow as a percentage of net worth — the "· ±x%" figure
    /// beside the hero. Shares the same base (`netWorth`) as the hero number so the
    /// percentage reads as "this month's flow relative to total net worth."
    var netFlowPercentage: Decimal {
        guard netWorth > 0 else { return 0 }
        return (netFlowThisMonth / netWorth) * 100
    }

    /// Six-month income / expense series driving the summary-card sparklines.
    var incomeSeries: [Decimal] { lastSixMonths.map(\.income) }
    var expenseSeries: [Decimal] { lastSixMonths.map(\.expense) }

    /// Six monthly net-worth values (oldest → newest) for the hero trend sparkline.
    /// Reuses `NetWorthViewModel`'s historical reconstruction (ledger running
    /// balances + loan/liability transactions). Note: investment/commodity holdings
    /// are valued at their *current* price for every month, so the trend is an
    /// approximation of past net worth, accurate for cash/account movement.
    var netWorthTrend: [Decimal] {
        let calendar = Calendar.current
        let now = Date()
        guard let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let start = calendar.date(byAdding: .month, value: -5, to: thisMonth) else { return [] }
        return NetWorthViewModel(modelContext: modelContext)
            .dataPoints(from: start, to: now)
            .map(\.netWorth)
    }

    // MARK: - Portfolio Gain / Loss

    /// Total unrealized profit/loss across the whole portfolio — PSX brokerage
    /// accounts, commodity holdings, and mutual-fund holdings — matching the set
    /// summed by `totalInvested`.
    var totalUnrealizedPL: Decimal {
        let psxPL = accounts.filter { $0.accountType == .psx }
            .reduce(0) { $0 + $1.totalProfitLoss }
        let commodityPL = allCommodityHoldings.filter { $0.totalGrams > 0 }
            .reduce(0) { $0 + $1.unrealizedPAndL }
        let mfPL = allMFHoldings.filter { $0.totalUnits > 0 }
            .reduce(0) { $0 + $1.unrealizedPAndL }
        return psxPL + commodityPL + mfPL
    }

    /// `totalUnrealizedPL` as a percentage of invested cost basis.
    var totalReturnPercentage: Decimal {
        let psxCost = accounts.filter { $0.accountType == .psx }
            .reduce(0) { $0 + $1.investedAmount }
        let commodityCost = allCommodityHoldings.filter { $0.totalGrams > 0 }
            .reduce(0) { $0 + $1.totalCost }
        let mfCost = allMFHoldings.filter { $0.totalUnits > 0 }
            .reduce(0) { $0 + $1.totalCost }
        let costBasis = psxCost + commodityCost + mfCost
        guard costBasis > 0 else { return 0 }
        return (totalUnrealizedPL / costBasis) * 100
    }

    // MARK: - Top Holdings

    enum HoldingKind {
        case stock, commodity, mutualFund
    }

    struct HoldingRow: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
        let value: Decimal
        let changePercent: Decimal
        let kind: HoldingKind
    }

    /// The highest-value investment holdings across PSX, commodities, and mutual funds.
    var topHoldings: [HoldingRow] {
        var rows: [HoldingRow] = []

        for holding in allHoldings where holding.totalShares > 0 {
            rows.append(HoldingRow(
                name: holding.companyName,
                subtitle: "\(holding.ticker) · \(holding.totalShares) shares",
                value: holding.currentValue,
                changePercent: changePercent(value: holding.currentValue, cost: holding.totalCost),
                kind: .stock
            ))
        }

        for holding in allCommodityHoldings where holding.totalGrams > 0 {
            rows.append(HoldingRow(
                name: holding.commodityName,
                subtitle: "\(holding.totalGrams.formattedNumber()) g",
                value: holding.currentValue,
                changePercent: changePercent(value: holding.currentValue, cost: holding.totalCost),
                kind: .commodity
            ))
        }

        for holding in allMFHoldings where holding.totalUnits > 0 {
            rows.append(HoldingRow(
                name: holding.schemeName,
                subtitle: holding.fundCode,
                value: holding.currentValue,
                changePercent: changePercent(value: holding.currentValue, cost: holding.totalCost),
                kind: .mutualFund
            ))
        }

        return rows.sorted { $0.value > $1.value }.prefix(4).map { $0 }
    }

    private func changePercent(value: Decimal, cost: Decimal) -> Decimal {
        guard cost > 0 else { return 0 }
        return ((value - cost) / cost) * 100
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

    private var allMFHoldings: [MutualFundHolding] {
        (try? modelContext.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
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
        let mfValue = allMFHoldings.filter { $0.totalUnits > 0 }
            .reduce(0) { $0 + $1.currentValue }
        return psxValue + commodityValue + mfValue
    }

    private var totalDebtorOutstanding: Decimal {
        allDebtors.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var totalCreditorOutstanding: Decimal {
        allCreditors.reduce(0) { $0 + $1.outstandingBalance }
    }

    // MARK: - Committees

    private var allCommittees: [Committee] {
        (try? modelContext.fetch(FetchDescriptor<Committee>())) ?? []
    }

    private var allCommitteePayouts: [CommitteePayout] {
        (try? modelContext.fetch(FetchDescriptor<CommitteePayout>())) ?? []
    }

    var totalCommitteeReceivable: Decimal {
        allCommittees.reduce(0) { result, committee in
            let received = allCommitteePayouts
                .filter { $0.committeeId == committee.id }
                .reduce(0) { $0 + $1.amount }
            return result + max(0, committee.myTotalPayout - received)
        }
    }

    var activeCommitteeCount: Int {
        allCommittees.filter { $0.isActive && !$0.isComplete }.count
    }

    private var incomeThisMonth: Decimal {
        allTransactions.filter { $0.date.isInCurrentMonth }
            .filter { $0.type == .income || $0.type == .committeePayout || $0.type == .commoditySell || $0.type == .mutualFundSell }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseThisMonth: Decimal {
        allTransactions.filter { $0.date.isInCurrentMonth }
            .filter { $0.type == .expense || $0.type == .committeeContribution || $0.type == .commodityBuy || $0.type == .mutualFundBuy }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Charts

    struct ExpenseBreakdown: Identifiable {
        let id = UUID()
        let category: String
        let total: Decimal
    }

    var expenseByCategory: [ExpenseBreakdown] {
        let transactions = allTransactions.filter { $0.date.isInCurrentMonth && ($0.type == .expense || $0.type == .committeeContribution || $0.type == .commodityBuy || $0.type == .mutualFundBuy) }
        let labeled = transactions.map { tx -> (label: String, amount: Decimal) in
            if tx.type == .committeeContribution { return ("Committee", tx.amount) }
            if tx.type == .commodityBuy { return ("Commodity", tx.amount) }
            if tx.type == .mutualFundBuy { return ("Mutual Fund", tx.amount) }
            return (tx.category ?? "Other", tx.amount)
        }
        let grouped = Dictionary(grouping: labeled, by: \.label)
        return grouped.map { ExpenseBreakdown(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    /// This month's income grouped by category, mirroring `expenseByCategory`.
    /// Investment/committee inflows are relabeled to their source rather than the
    /// underlying transaction category.
    var incomeByCategory: [ExpenseBreakdown] {
        let transactions = allTransactions.filter { $0.date.isInCurrentMonth && ($0.type == .income || $0.type == .committeePayout || $0.type == .commoditySell || $0.type == .mutualFundSell) }
        let labeled = transactions.map { tx -> (label: String, amount: Decimal) in
            if tx.type == .committeePayout { return ("Committee", tx.amount) }
            if tx.type == .commoditySell { return ("Commodity", tx.amount) }
            if tx.type == .mutualFundSell { return ("Mutual Fund", tx.amount) }
            return (tx.category ?? "Other", tx.amount)
        }
        let grouped = Dictionary(grouping: labeled, by: \.label)
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
            let income = monthlyTxs.filter { $0.type == .income || $0.type == .committeePayout || $0.type == .commoditySell || $0.type == .mutualFundSell }.reduce(0) { $0 + $1.amount }
            let expense = monthlyTxs.filter { $0.type == .expense || $0.type == .committeeContribution || $0.type == .commodityBuy || $0.type == .mutualFundBuy }.reduce(0) { $0 + $1.amount }
            return MonthlyComparison(month: monthStart, income: income, expense: expense)
        }
    }

    var recentTransactions: [Transaction] {
        allTransactions.sorted { $0.date > $1.date }.prefix(5).map { $0 }
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

    // MARK: - Asset Allocation Pie Chart

    struct AllocationSlice: Identifiable {
        let id = UUID()
        let label: String
        let value: Decimal
        let color: String
    }

    var assetAllocation: [AllocationSlice] {
        let psxValue = accounts.filter { $0.accountType == .psx }.reduce(0) { $0 + $1.currentValue }
        let commodityValue = allCommodityHoldings.filter { $0.totalGrams > 0 }.reduce(0) { $0 + $1.currentValue }
        let mfValue = allMFHoldings.filter { $0.totalUnits > 0 }.reduce(0) { $0 + $1.currentValue }

        return [
            AllocationSlice(label: "PSX", value: psxValue, color: "psx"),
            AllocationSlice(label: "Commodities", value: commodityValue, color: "commodity"),
            AllocationSlice(label: "Mutual Funds", value: mfValue, color: "mutualFund"),
            AllocationSlice(label: "Banks", value: totalBankBalances, color: "bank"),
            AllocationSlice(label: "Cash", value: totalCashBalances, color: "cash"),
            AllocationSlice(label: "Receivable", value: totalDebtorOutstanding, color: "receivable"),
            AllocationSlice(label: "Committee", value: totalCommitteeReceivable, color: "committee"),
            AllocationSlice(label: "Liabilities", value: totalLiabilities, color: "liability")
        ].filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
    }

    var hasNoData: Bool {
        accounts.isEmpty
            && allTransactions.isEmpty
            && allDebtors.isEmpty
            && allCreditors.isEmpty
            && allCommittees.isEmpty
            && allCommodityHoldings.isEmpty
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