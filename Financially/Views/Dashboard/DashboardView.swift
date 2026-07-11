import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: DashboardViewModel?
    @State private var activeSheet: DashboardSheet?
    @State private var showQuickActions = false
    @State private var showAllTransactions = false

    var body: some View {
        NavigationStack {
            if let vm {
                content(vm)
            }
        }
        .onAppear {
            vm = DashboardViewModel(modelContext: modelContext)
        }
        .sheet(item: $activeSheet) { sheet in
            sheet.destination
        }
        .persistentGlassSheet(
            isPresented: $showQuickActions,
            detents: [.height(140), .medium, .large],
            interactiveUpThrough: .height(140)
        ) {
            QuickActionsSheetContent(sections: quickActionSections)
        }
    }

    private func content(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: DesignSpacing.lg) {
                DashboardHeaderView(vm: vm)

                VStack(spacing: DesignSpacing.lg) {
                    if vm.hasNoData { emptyDashboardCard }

                    if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryCard(
                                title: "Monthly Income",
                                amount: vm.monthlyIncome,
                                icon: "arrow.down.circle.fill",
                                color: .gain
                            )
                            SummaryCard(
                                title: "Monthly Expense",
                                amount: vm.monthlyExpense,
                                icon: "arrow.up.circle.fill",
                                color: .loss
                            )
                        }
                    }

                    if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 { incomeVsExpenseWidget(vm) }
                    if vm.monthlyExpense > 0 { expenseChartWidget(vm) }
                    if !vm.assetAllocation.isEmpty { AllocationPieChart(slices: vm.assetAllocation) }
                    if vm.activeLoanCount > 0 || vm.activeLiabilityCount > 0 || vm.activeCommitteeCount > 0 { activeLoansWidget(vm) }
                    if !vm.recentTransactions.isEmpty { recentTransactionsSection(vm) }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .scrollClipDisabled()
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Dashboard")
                    .font(.headline)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { activeSheet = .settings }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
                .buttonStyle(.glass)
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showQuickActions = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Quick Actions

    private func selectQuickAction(_ sheet: DashboardSheet) {
        showQuickActions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            activeSheet = sheet
        }
    }

    private var quickActionSections: [QuickActionSection] {
        [
            QuickActionSection(title: "Most Used", items: [
                QuickActionItem(title: "Expense", systemImage: "arrow.up.circle.fill", tint: .loss) { selectQuickAction(.expense) },
                QuickActionItem(title: "Income", systemImage: "arrow.down.circle.fill", tint: .gain) { selectQuickAction(.income) },
                QuickActionItem(title: "Transfer", systemImage: "arrow.left.arrow.right", tint: .brandTint) { selectQuickAction(.transfer) }
            ]),
            QuickActionSection(title: "Invest", items: [
                QuickActionItem(title: "Buy Stock", systemImage: "chart.bar.fill", tint: .indigo) { selectQuickAction(.buyStock) },
                QuickActionItem(title: "Invest MF", systemImage: "chart.pie.fill", tint: .teal) { selectQuickAction(.investMF) },
                QuickActionItem(title: "Buy Gold", systemImage: "diamond.fill", tint: .orange) { selectQuickAction(.buyGold) }
            ]),
            QuickActionSection(title: "People & Committees", items: [
                QuickActionItem(title: "Give Loan", systemImage: "arrow.right.circle.fill", tint: .brandTint) { selectQuickAction(.giveLoan) },
                QuickActionItem(title: "Pay Committee", systemImage: "person.2.fill", tint: .teal) { selectQuickAction(.payCommittee) },
                QuickActionItem(title: "Pay Back", systemImage: "arrow.up.circle.fill", tint: .loss) { selectQuickAction(.payBack) }
            ])
        ]
    }

    // MARK: - Empty Dashboard

    private var emptyDashboardCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Welcome to Financially")
                .font(.headline)
            Text("Track your money — accounts, investments, loans, committees & more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .dataCard()
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
        .dataCard()
    }

    // MARK: - Active Loans / Liabilities

    private func activeLoansWidget(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Commitments")
                .font(.headline)

            HStack(spacing: 12) {
                activeWidget(
                    title: "Active Loans",
                    count: vm.activeLoanCount,
                    total: vm.activeLoanTotal,
                    icon: "arrow.left.arrow.right",
                    color: .brandTint
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
                .tabularNumbers()
                .lineLimit(1)
            Text(total.formattedCurrency())
                .font(.caption)
                .tabularNumbers()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .dataCard()
    }

    // MARK: - Recent Transactions

    private func recentTransactionsSection(_ vm: DashboardViewModel) -> some View {
        RecentTransactionsView(transactions: vm.recentTransactions, onViewAll: { showAllTransactions = true })
            .sheet(isPresented: $showAllTransactions) {
                NavigationStack { TransactionHistoryReport() }
            }
    }
}

// MARK: - Sheet Routing

private enum DashboardSheet: String, Identifiable {
    case expense, income, transfer, buyStock, investMF, buyGold, giveLoan, payCommittee, payBack, settings

    var id: String { rawValue }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .expense: AddExpenseView()
        case .income: AddIncomeView()
        case .transfer: TransferView()
        case .buyStock: InvestmentsListView(initialSegment: .psx)
        case .investMF: InvestmentsListView(initialSegment: .mutualFunds)
        case .buyGold: BuyCommodityView()
        case .giveLoan: LoansListView(initialSegment: .debtors)
        case .payCommittee: CommitteesListView()
        case .payBack: LoansListView(initialSegment: .creditors)
        case .settings: SettingsView()
        }
    }
}
