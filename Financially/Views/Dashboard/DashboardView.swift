import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @Query private var debtors: [Debtor]
    @Query private var creditors: [Creditor]

    @State private var showExpense = false
    @State private var showIncome = false
    @State private var showTransfer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    accountsGridScroll
                    expenseChartWidget
                    incomeVsExpenseWidget
                    activeLoansWidget
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Expense", systemImage: "cart.fill") { showExpense = true }
                        Button("Income", systemImage: "dollarsign.circle.fill") { showIncome = true }
                        Button("Transfer", systemImage: "arrow.left.arrow.right") { showTransfer = true }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showExpense) { AddExpenseView() }
        .sheet(isPresented: $showIncome) { AddIncomeView() }
        .sheet(isPresented: $showTransfer) { TransferView() }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Net Worth",
                amount: computeNetWorth,
                icon: "heart.fill",
                color: .netWorthAccent
            )
            SummaryCard(
                title: "Total Assets",
                amount: computeTotalAssets,
                icon: "building.columns.fill",
                color: .assetsAccent
            )
            SummaryCard(
                title: "Liabilities",
                amount: computeTotalLiabilities,
                icon: "arrow.right.circle.fill",
                color: .liabilitiesAccent
            )
            SummaryCard(
                title: "Receivables",
                amount: computeTotalReceivables,
                icon: "arrow.left.circle.fill",
                color: .receivablesAccent
            )
            SummaryCard(
                title: "Monthly Income",
                amount: computeMonthlyIncome,
                icon: "arrow.down.circle.fill",
                color: .incomeGreen
            )
            SummaryCard(
                title: "Monthly Expense",
                amount: computeMonthlyExpense,
                icon: "arrow.up.circle.fill",
                color: .expenseRed
            )
        }
    }

    // MARK: - Accounts Overview

    private var accountsGridScroll: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accounts")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(accounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            accountCard(account)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if account.accountType == .bank, let bankName = account.bankName {
                BankLogoView(bankName: bankName, size: 32)
            } else {
                Image(systemName: accountIcon(account))
                    .font(.title3)
            }
            Text(account.name)
                .font(.caption)
                .lineLimit(1)
            Text(account.currentBalance.formattedCurrency(currency: account.currency))
                .font(.caption.bold())
        }
        .frame(width: 100)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Expense Chart

    private var expenseChartWidget: some View {
        ExpenseChartWidget(expenseByCategory: computeExpenseByCategory, totalExpense: computeMonthlyExpense)
    }

    // MARK: - Income vs Expense

    private var incomeVsExpenseWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs Expense")
                .font(.headline)

            BarChartView(data: computeMonthlyComparisons)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Active Loans / Liabilities

    private var activeLoansWidget: some View {
        HStack(spacing: 12) {
            activeWidget(
                title: "Active Loans",
                count: activeLoanCount,
                total: activeLoanTotal,
                icon: "arrow.left.arrow.right",
                color: .blue
            )
            activeWidget(
                title: "Liabilities Held",
                count: activeLiabilityCount,
                total: activeLiabilityTotal,
                icon: "arrow.right.circle",
                color: .orange
            )
        }
    }

    private func activeWidget(title: String, count: Int, total: Decimal, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("\(count)")
                .font(.title2.bold())
            Text(total.formattedCurrency())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        RecentTransactionsView(transactions: recentTransactions)
    }

    // MARK: - Computed Properties

    private var computeNetWorth: Decimal {
        computeTotalAssets - computeTotalLiabilities + computeTotalReceivables
    }

    private var computeTotalAssets: Decimal {
        accounts.filter { $0.isActive }.reduce(0) { sum, account in
            if account.accountType == .psx || account.accountType == .mutualFund {
                return sum + account.currentValue
            }
            return sum + account.currentBalance
        }
    }

    private var computeTotalLiabilities: Decimal {
        creditors.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var computeTotalReceivables: Decimal {
        debtors.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var computeMonthlyIncome: Decimal {
        transactions.filter { $0.type == .income && $0.date.isInCurrentMonth }
            .reduce(0) { $0 + $1.amount }
    }

    private var computeMonthlyExpense: Decimal {
        transactions.filter { $0.type == .expense && $0.date.isInCurrentMonth }
            .reduce(0) { $0 + $1.amount }
    }

    private var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    private var computeExpenseByCategory: [DashboardViewModel.ExpenseBreakdown] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense && $0.date.isInCurrentMonth }) { $0.category ?? "Other" }
        return grouped.map { DashboardViewModel.ExpenseBreakdown(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    private var computeMonthlyComparisons: [DashboardViewModel.MonthlyComparison] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { monthsAgo in
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.date(byAdding: .month, value: -monthsAgo, to: now)!))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            let monthlyTxs = transactions.filter { $0.date >= monthStart && $0.date <= monthEnd }
            let income = monthlyTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthlyTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return DashboardViewModel.MonthlyComparison(month: monthStart, income: income, expense: expense)
        }
    }

    private var activeLoanCount: Int {
        debtors.filter { !$0.isSettled }.count
    }

    private var activeLiabilityCount: Int {
        creditors.filter { !$0.isSettled }.count
    }

    private var activeLoanTotal: Decimal {
        debtors.filter { !$0.isSettled }.reduce(0) { $0 + $1.outstandingBalance }
    }

    private var activeLiabilityTotal: Decimal {
        creditors.filter { !$0.isSettled }.reduce(0) { $0 + $1.outstandingBalance }
    }

    private func accountIcon(_ account: Account) -> String {
        account.icon ?? {
            switch account.accountType {
            case .bank: return "building.columns.fill"
            case .cash: return "wallet.pass.fill"
            case .psx: return "chart.line.uptrend.xyaxis"
            case .mutualFund: return "chart.pie.fill"
            }
        }()
    }
}