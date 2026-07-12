import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) private var themeManager

    @State private var vm: DashboardViewModel?
    @State private var showSettings = false
    @State private var showAllTransactions = false
    @State private var showInvestments = false
    @State private var showDebtors = false
    @State private var showCreditors = false
    @State private var showCommittees = false
    @State private var isScrolledPastHero = false

    var body: some View {
        NavigationStack {
            if let vm {
                content(vm)
            }
        }
        .onAppear {
            vm = DashboardViewModel(modelContext: modelContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func content(_ vm: DashboardViewModel) -> some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            HeroBackgroundView(theme: themeManager.theme, pattern: themeManager.pattern)

            scrollBody(vm)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Dashboard")
                    .font(.headline)
                    .foregroundStyle(isScrolledPastHero ? Color.primary : heroForeground)
                    .animation(.easeInOut(duration: 0.2), value: isScrolledPastHero)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
                .glassIconButton()
            }
        }
    }

    /// Text/icon color for content sitting on the hero gradient, from the active theme.
    private var heroForeground: Color {
        themeManager.theme.foreground(for: colorScheme)
    }

    private func scrollBody(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: DesignSpacing.lg) {
                DashboardHeaderView(vm: vm, foreground: heroForeground)

                VStack(spacing: DesignSpacing.lg) {
                    if vm.hasNoData { emptyDashboardCard }

                    if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryCard(
                                title: "Income",
                                amount: vm.monthlyIncome,
                                icon: "arrow.down.circle.fill",
                                color: .gain,
                                valueColored: true,
                                sparkline: vm.incomeSeries
                            )
                            SummaryCard(
                                title: "Expense",
                                amount: vm.monthlyExpense,
                                icon: "arrow.up.circle.fill",
                                color: .loss,
                                valueColored: true,
                                sparkline: vm.expenseSeries
                            )
                        }
                    }

                    if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 { incomeVsExpenseWidget(vm) }
                    if vm.monthlyExpense > 0 || vm.monthlyIncome > 0 { expenseChartWidget(vm) }
                    if !vm.topHoldings.isEmpty { holdingsWidget(vm) }
                    if !vm.assetAllocation.isEmpty { AllocationPieChart(slices: vm.assetAllocation) }
                    if vm.activeLoanCount > 0 || vm.activeLiabilityCount > 0 || vm.activeCommitteeCount > 0 { activeLoansWidget(vm) }
                    if !vm.recentTransactions.isEmpty { recentTransactionsSection(vm) }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .scrollClipDisabled()
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 60
        } action: { _, newValue in
            isScrolledPastHero = newValue
        }
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
        .dashboardCard()
    }

    // MARK: - Holdings

    private func holdingsWidget(_ vm: DashboardViewModel) -> some View {
        let pl = vm.totalUnrealizedPL
        let plPercent = vm.totalReturnPercentage
        return VStack(spacing: 0) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                Spacer()
                if pl != 0 {
                    HStack(spacing: 4) {
                        Text("\(pl >= 0 ? "+" : "-")\(abs(pl).formattedCurrency())")
                        Text("· \(plPercent >= 0 ? "+" : "")\(plPercent.formatted(.number.precision(.fractionLength(1))))%")
                    }
                    .font(.caption.weight(.semibold))
                    .tabularNumbers()
                    .foregroundStyle(pl >= 0 ? .gain : .loss)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ForEach(Array(vm.topHoldings.enumerated()), id: \.element.id) { index, holding in
                holdingRow(holding)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                if index != vm.topHoldings.count - 1 {
                    Divider().padding(.leading, 64)
                }
            }
            .padding(.bottom, 4)
        }
        .dashboardCard()
        .contentShape(Rectangle())
        .onTapGesture { showInvestments = true }
        .sheet(isPresented: $showInvestments) {
            NavigationStack { InvestmentsListView(initialSegment: .psx) }
        }
    }

    private func holdingRow(_ holding: DashboardViewModel.HoldingRow) -> some View {
        let style = holdingStyle(holding.kind)
        return HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.subheadline)
                .foregroundStyle(style.tint)
                .frame(width: 40, height: 40)
                .background(style.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(holding.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.value.formattedCurrency())
                    .font(.subheadline.weight(.semibold))
                    .tabularNumbers()
                    .lineLimit(1)
                Text("\(holding.changePercent >= 0 ? "+" : "")\(holding.changePercent.formatted(.number.precision(.fractionLength(1))))%")
                    .font(.caption)
                    .tabularNumbers()
                    .foregroundStyle(holding.changePercent >= 0 ? .gain : .loss)
            }
        }
    }

    private func holdingStyle(_ kind: DashboardViewModel.HoldingKind) -> (icon: String, tint: Color) {
        switch kind {
        case .stock: return ("chart.bar.fill", .indigo)
        case .commodity: return ("diamond.fill", .orange)
        case .mutualFund: return ("chart.pie.fill", .teal)
        }
    }

    // MARK: - Expense Chart

    private func expenseChartWidget(_ vm: DashboardViewModel) -> some View {
        ExpenseChartWidget(
            expenseByCategory: vm.expenseByCategory,
            totalExpense: vm.monthlyExpense,
            incomeByCategory: vm.incomeByCategory,
            totalIncome: vm.monthlyIncome
        )
    }

    // MARK: - Income vs Expense

    private func incomeVsExpenseWidget(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs Expense")
                .font(.headline)

            BarChartView(data: vm.lastSixMonths)
        }
        .padding()
        .dashboardCard()
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
                    color: themeManager.theme.accent,
                    action: { showDebtors = true }
                )
                activeWidget(
                    title: "Liabilities Held",
                    count: vm.activeLiabilityCount,
                    total: vm.activeLiabilityTotal,
                    icon: "arrow.right.circle",
                    color: .orange,
                    action: { showCreditors = true }
                )
                activeWidget(
                    title: "Active Committees",
                    count: vm.activeCommitteeCount,
                    total: vm.totalCommitteeReceivable,
                    icon: "person.3.fill",
                    color: .teal,
                    action: { showCommittees = true }
                )
            }
        }
        .sheet(isPresented: $showDebtors) {
            NavigationStack { LoansListView(initialSegment: .debtors) }
        }
        .sheet(isPresented: $showCreditors) {
            NavigationStack { LoansListView(initialSegment: .creditors) }
        }
        .sheet(isPresented: $showCommittees) {
            NavigationStack { CommitteesListView() }
        }
    }

    private func activeWidget(title: String, count: Int, total: Decimal, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .dashboardCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Transactions

    private func recentTransactionsSection(_ vm: DashboardViewModel) -> some View {
        RecentTransactionsView(transactions: vm.recentTransactions, onViewAll: { showAllTransactions = true })
            .sheet(isPresented: $showAllTransactions) {
                NavigationStack { TransactionHistoryReport() }
            }
    }
}
