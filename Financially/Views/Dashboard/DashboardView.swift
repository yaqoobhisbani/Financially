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
                if vm.activeLoanCount > 0 || vm.activeLiabilityCount > 0 || vm.activeCommitteeCount > 0 { activeLoansWidget(vm) }
                if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 { incomeVsExpenseWidget(vm) }
                if vm.monthlyExpense > 0 { expenseChartWidget(vm) }
                if !vm.recentTransactions.isEmpty { recentTransactionsSection(vm) }
            }
            .padding()
        }
        .scrollClipDisabled(true)
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
            .scrollClipDisabled(true)
        }
    }

    private func accountCard(_ account: Account, _ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                if account.accountType == .bank, let bankName = account.bankName {
                    BankLogoView(bankName: bankName, size: 18)
                        .frame(width: 18, height: 18)
                } else if account.accountType == .psx {
                    Image("PSXLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: account.icon ?? accountTypeIcon(account.accountType))
                        .font(.system(size: 16, weight: .medium))
                        .offset(x: -2)
                        .frame(width: 18, height: 18)
                }
                Text(account.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            Text(account.accountType == .psx ? (account.currentBalance + vm.psxPortfolioValue(account)).formattedCurrency(currency: account.currency) : account.currentBalance.formattedCurrency(currency: account.currency))
                .font(.subheadline.bold())
                .lineLimit(1)
            if account.accountType == .psx {
                let pnl = vm.psxProfitLoss(account.id)
                Text("\(pnl >= 0 ? "+" : "")\(pnl.formattedCurrency(currency: account.currency))")
                    .font(.caption)
                    .foregroundStyle(pnl >= 0 ? .incomeGreen : .expenseRed)
                    .lineLimit(1)
            } else if account.accountType == .bank {
                if let acctNum = account.accountNumber, acctNum.count >= 4 {
                    Text("•••• \(acctNum.suffix(4))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else if let subType = account.bankSubType {
                    Text(subType.rawValue == "traditional" ? "Bank" : subType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            } else if account.accountType == .cash {
                Text(account.cashSubType?.rawValue.capitalized ?? "Cash")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(width: 120, height: 72, alignment: .center)
        .padding(10)
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
        .liquidGlassCard()
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
        .liquidGlassCard()
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
            activeWidget(
                title: "Active Committees",
                count: vm.activeCommitteeCount,
                total: vm.totalCommitteeReceivable,
                icon: "person.3.fill",
                color: .teal
            )
        }
    }

    private func activeWidget(title: String, count: Int, total: Decimal, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .fixedSize()
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text("\(count)")
                .font(.title2.bold())
                .lineLimit(1)
            Text(total.formattedCurrency())
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .liquidGlassCard()
    }

    // MARK: - Recent Transactions

    private func recentTransactionsSection(_ vm: DashboardViewModel) -> some View {
        RecentTransactionsView(transactions: vm.recentTransactions)
    }
}