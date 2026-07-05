import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: DashboardViewModel?
    @State private var showExpense = false
    @State private var showIncome = false
    @State private var showTransfer = false

    var body: some View {
        NavigationStack {
            if let vm {
                content(vm)
            }
        }
        .onAppear {
            vm = DashboardViewModel(modelContext: modelContext)
        }
        .sheet(isPresented: $showExpense) { AddExpenseView() }
        .sheet(isPresented: $showIncome) { AddIncomeView() }
        .sheet(isPresented: $showTransfer) { TransferView() }
    }

    private func content(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCards(vm)
                if !vm.assetAllocation.isEmpty { AllocationPieChart(slices: vm.assetAllocation) }
                if !vm.accounts.isEmpty { accountsGridScroll(vm) }
                commoditiesSection(vm)
                if vm.activeLoanCount > 0 || vm.activeLiabilityCount > 0 { activeLoansWidget(vm) }
                if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 { incomeVsExpenseWidget(vm) }
                if vm.monthlyExpense > 0 { expenseChartWidget(vm) }
                if !vm.recentTransactions.isEmpty { recentTransactionsSection(vm) }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    // MARK: - Summary Cards

    private func summaryCards(_ vm: DashboardViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Net Worth",
                amount: vm.netWorth,
                icon: "heart.fill",
                color: .netWorthAccent
            )
            SummaryCard(
                title: "Total Assets",
                amount: vm.totalOwnFunds + vm.totalReceivables,
                icon: "building.columns.fill",
                color: .assetsAccent
            )
            SummaryCard(
                title: "Liabilities",
                amount: vm.totalLiabilities,
                icon: "arrow.right.circle.fill",
                color: .liabilitiesAccent
            )
            SummaryCard(
                title: "Receivables",
                amount: vm.totalReceivables,
                icon: "arrow.left.circle.fill",
                color: .receivablesAccent
            )
            SummaryCard(
                title: "Monthly Income",
                amount: vm.monthlyIncome,
                icon: "arrow.down.circle.fill",
                color: .incomeGreen
            )
            SummaryCard(
                title: "Monthly Expense",
                amount: vm.monthlyExpense,
                icon: "arrow.up.circle.fill",
                color: .expenseRed
            )
        }
    }

    // MARK: - Accounts Overview

    private func accountsGridScroll(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accounts")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.accounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            accountCard(account, vm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func accountCard(_ account: Account, _ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if account.accountType == .bank, let bankName = account.bankName {
                BankLogoView(bankName: bankName, size: 32)
            } else if account.accountType == .psx {
                Image("PSXLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: account.icon ?? accountTypeIcon(account.accountType))
                    .font(.title3)
                    .frame(height: 32)
            }
            Text(account.name)
                .font(.caption)
                .lineLimit(1)
            Text(account.accountType == .psx ? (account.currentBalance + vm.psxPortfolioValue(account)).formattedCurrency(currency: account.currency) : account.currentBalance.formattedCurrency(currency: account.currency))
                .font(.caption2)
            if account.accountType == .psx {
                Text(vm.psxProfitLoss(account.id).formattedCurrency(currency: account.currency))
                    .font(.caption2)
                    .foregroundStyle(vm.psxProfitLoss(account.id) >= 0 ? .incomeGreen : .expenseRed)
            }
        }
        .frame(width: 100, height: 100)
        .padding()
        .liquidGlassCard()
    }

    private func accountTypeIcon(_ type: AccountType) -> String {
        switch type {
        case .bank: return "building.columns.fill"
        case .cash: return "wallet.pass.fill"
        case .psx: return "chart.line.uptrend.xyaxis"
        }
    }

    // MARK: - Commodities Section

    private func commoditiesSection(_ vm: DashboardViewModel) -> some View {
        Group {
            let holdings = vm.activeCommodityHoldings
            if !holdings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commodities")
                        .font(.headline)

                    ForEach(holdings) { holding in
                        NavigationLink(destination: CommodityHoldingDetailView(holding: holding)) {
                            commodityCard(holding)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func commodityCard(_ holding: CommodityHolding) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "diamond.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.commodityName)
                    .font(.caption)
                Text("\(holding.totalGrams.formattedNumber()) g @ \(holding.avgCostPerGram.formattedCurrency())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.currentValue.formattedCurrency())
                    .font(.caption.bold())
                Text(holding.unrealizedPAndL.formattedCurrency())
                    .font(.caption2)
                    .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Expense Chart

    private func expenseChartWidget(_ vm: DashboardViewModel) -> some View {
        ExpenseChartWidget(expenseByCategory: vm.expenseByCategory, totalExpense: vm.monthlyExpense)
    }

    // MARK: - Income vs Expense

    private func incomeVsExpenseWidget(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs Expense")
                .font(.headline)

            BarChartView(data: vm.lastSixMonths)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Active Loans / Liabilities

    private func activeLoansWidget(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: 12) {
            activeWidget(
                title: "Active Loans",
                count: vm.activeLoanCount,
                total: vm.activeLoanTotal,
                icon: "arrow.left.arrow.right",
                color: .blue
            )
            activeWidget(
                title: "Liabilities Held",
                count: vm.activeLiabilityCount,
                total: vm.activeLiabilityTotal,
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
        .liquidGlassCard()
    }

    // MARK: - Recent Transactions

    private func recentTransactionsSection(_ vm: DashboardViewModel) -> some View {
        RecentTransactionsView(transactions: vm.recentTransactions)
    }
}