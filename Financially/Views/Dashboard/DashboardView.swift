import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: DashboardViewModel?
    @State private var showExpense = false
    @State private var showIncome = false
    @State private var showTransfer = false
    @State private var scrollOffset: CGFloat = 0
    @State private var activeLoansTitleY: CGFloat = 0

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
        GeometryReader { geo in
            let heroHeight = geo.size.height * 0.55
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [Color(hex: "#2563EB") ?? .blue, Color(hex: "#1D4ED8") ?? Color(red: 0.11, green: 0.31, blue: 0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: heroHeight)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        DashboardHeaderView(vm: vm)
                            .padding(.horizontal, -16)

                        if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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

                        if !vm.assetAllocation.isEmpty { AllocationPieChart(slices: vm.assetAllocation) }
                        if vm.activeLoanCount > 0 || vm.activeLiabilityCount > 0 || vm.activeCommitteeCount > 0 { activeLoansWidget(vm, heroHeight: heroHeight) }
                        if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 { incomeVsExpenseWidget(vm) }
                        if vm.monthlyExpense > 0 { expenseChartWidget(vm) }
                        if !vm.recentTransactions.isEmpty { recentTransactionsSection(vm) }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(minHeight: geo.size.height)
                    .background(GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    })
                }
                .scrollClipDisabled(true)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Dashboard")
                    .font(.headline)
                    .foregroundStyle(scrollOffset > -60 ? .white : .primary)
                    .animation(.easeInOut(duration: 0.2), value: scrollOffset)
            }
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

    private func activeLoansWidget(_ vm: DashboardViewModel, heroHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Loans / Liabilities / Committees")
                .font(.headline)
                .foregroundStyle(activeLoansTitleY < heroHeight ? .white : .primary)
                .animation(.easeInOut(duration: 0.15), value: activeLoansTitleY)
                .background(GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global).minY) { _, v in activeLoansTitleY = v }
                        .onAppear { activeLoansTitleY = proxy.frame(in: .global).minY }
                })

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

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}