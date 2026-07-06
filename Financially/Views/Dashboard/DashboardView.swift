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
                DashboardHeaderView(vm: vm)
                    .padding(.horizontal, -16)
                    .padding(.top, -16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SummaryCard(
                        title: "In Accounts",
                        amount: vm.totalAccounts,
                        icon: "building.columns.fill",
                        color: .blue
                    )
                    SummaryCard(
                        title: "Invested",
                        amount: vm.totalInvested,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                    SummaryCard(
                        title: "Liabilities",
                        amount: vm.totalLiabilities,
                        icon: "arrow.right.circle.fill",
                        color: .orange
                    )
                    SummaryCard(
                        title: "Receivables",
                        amount: vm.totalReceivables,
                        icon: "arrow.left.circle.fill",
                        color: .teal
                    )
                }

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
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Loans / Liabilities / Committees")
                .font(.headline)

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