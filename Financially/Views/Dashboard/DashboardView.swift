import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var vm: DashboardViewModel?
    @State private var activeSheet: DashboardSheet?
    @State private var showQuickActions = false
    @State private var showAllTransactions = false
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
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            heroGradient
                .ignoresSafeArea()

            scrollBody(vm)
        }
        .overlay(alignment: .bottomTrailing) { quickAddButton }
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
                Button(action: { activeSheet = .settings }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
                .buttonStyle(.glass)
            }
        }
    }

    /// Full-screen hero wash, top-right → bottom-left. A pale, airy blue in light mode
    /// (paired with dark text); the deeper cobalt brand tint in dark mode (white text).
    private var heroGradient: some View {
        let top = colorScheme == .dark
            ? Color.brandTint
            : Color(red: 0.66, green: 0.80, blue: 0.98)
        return LinearGradient(
            stops: [
                .init(color: top, location: 0.0),
                .init(color: top.opacity(0.9), location: 0.46),
                .init(color: top.opacity(0.0), location: 0.74)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Text/icon color for content sitting on the hero gradient.
    private var heroForeground: Color {
        colorScheme == .dark ? .white : Color(red: 0.08, green: 0.13, blue: 0.30)
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

                    if !vm.topHoldings.isEmpty { holdingsWidget(vm) }
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
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 60
        } action: { _, newValue in
            isScrolledPastHero = newValue
        }
    }

    private var quickAddButton: some View {
        Button(action: { showQuickActions = true }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .frame(width: 60, height: 60)
        }
        .buttonStyle(.glassProminent)
        .clipShape(Circle())
        .padding(.trailing, DesignSpacing.lg)
        .padding(.bottom, DesignSpacing.xxl)
        .accessibilityLabel("Quick actions")
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

    // MARK: - Holdings

    private func holdingsWidget(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                Spacer()
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
        .dataCard()
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
