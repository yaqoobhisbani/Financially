import SwiftUI
import SwiftData

struct MFAccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var vm: MFPortfolioViewModel?
    @State private var showInvest = false
    @State private var showRedeem = false
    @State private var showEdit = false
    @State private var selectedTransaction: Transaction?
    @State private var showStatement = false

    var body: some View {
        if let vm {
            content(vm: vm)
        } else {
            ProgressView()
                .onAppear {
                    vm = MFPortfolioViewModel(modelContext: modelContext, account: account)
                }
        }
    }

    private func content(vm: MFPortfolioViewModel) -> some View {
        List {
            balanceSection(vm: vm)
            actionsSection
            holdingsSection(vm: vm)
            recentTransactionsSection(vm: vm)
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("View Statement", systemImage: "doc.text") { showStatement = true }
                    Button("Edit Account", systemImage: "pencil") { showEdit = true }
                    Button(account.isActive ? "Deactivate" : "Activate", systemImage: account.isActive ? "eye.slash" : "eye") {
                        vm.toggleActive()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showInvest) { InvestView(account: account) }
        .sheet(isPresented: $showRedeem) { RedeemView(account: account) }
        .sheet(isPresented: $showEdit) { EditAccountView(account: account) }
        .sheet(isPresented: $showStatement) { MFStatementView(account: account) }
    }

    private func balanceSection(vm: MFPortfolioViewModel) -> some View {
        Section {
            SummaryBalanceView(
                heroLeftLabel: "Total Portfolio",
                heroLeftValue: vm.totalHoldingValue.formattedCurrency(),
                heroRightLabel: "P&L",
                heroRightValue: vm.totalUnrealizedPAndL.formattedCurrency(),
                heroRightColor: vm.totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed,
                detailRows: [
                    [
                        AnyView(SummaryMetric(label: "Holdings Value", value: vm.totalHoldingValue.formattedCurrency())),
                        AnyView(SummaryMetric(label: "Total Cost", value: vm.totalCostBasis.formattedCurrency(), alignment: .trailing))
                    ],
                    [
                        AnyView(SummaryMetricView(label: "Return") { PercentageText(value: vm.totalPAndLPercentage).foregroundStyle(vm.totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed) }),
                        AnyView(SummaryMetric(label: "Unrealized P&L", value: vm.totalUnrealizedPAndL.formattedCurrency(), color: vm.totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed, alignment: .trailing))
                    ]
                ]
            )
        }
    }

    private var actionsSection: some View {
        Section {
            HStack(spacing: 10) {
                ActionCard(label: "Invest", icon: "plus.circle.fill", color: .incomeGreen) { showInvest = true }
                ActionCard(label: "Redeem", icon: "minus.circle.fill", color: .expenseRed) { showRedeem = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Text("Actions")
        }
    }

    private func holdingsSection(vm: MFPortfolioViewModel) -> some View {
        Section("Holdings") {
            if vm.accountHoldings.isEmpty {
                EmptyStateView(title: "No holdings yet", systemImage: "chart.pie.fill", description: "Invest in a scheme to get started")
            }
            ForEach(vm.accountHoldings) { holding in
                NavigationLink(destination: MFHoldingDetailView(account: account, holding: holding)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.schemeName)
                                .font(.headline)
                            Text(holding.fundCode)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(holding.totalUnits.formattedNumber()) units @ \(holding.avgNavPrice.formattedCurrency())")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(holding.currentValue.formattedCurrency())
                                .font(.subheadline.bold())
                            Text(holding.unrealizedPAndL.formattedCurrency())
                                .font(.caption)
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func recentTransactionsSection(vm: MFPortfolioViewModel) -> some View {
        Section {
            ForEach(Array(vm.mfTransactions.prefix(5))) { tx in
                TransactionRowView(transaction: tx, showIcon: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTransaction = tx
                    }
            }

            if vm.mfTransactions.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        } header: {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button("View All") { showStatement = true }
                    .font(.subheadline)
            }
            .listRowInsets(EdgeInsets())
        }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack { TransactionDetailView(transaction: tx) }
        }
    }
}

struct MFStatementView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var vm: MFPortfolioViewModel?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var datePreset = DateRangePickerView.DatePreset.thisMonth

    var body: some View {
        NavigationStack {
            if let vm {
                List {
                    Section {
                        DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $datePreset)
                    }

                    Section("Transactions") {
                        let filtered = vm.mfTransactions.filter { $0.date >= startDate && $0.date <= endDate }
                        if filtered.isEmpty {
                            EmptyStateView(title: "No transactions in this period", systemImage: "arrow.left.arrow.right")
                        }
                        ForEach(filtered) { tx in
                            TransactionRowView(transaction: tx, showIcon: true)
                        }
                    }
                }
                .navigationTitle("Statement")
            } else {
                ProgressView()
                    .onAppear {
                        vm = MFPortfolioViewModel(modelContext: modelContext, account: account)
                    }
            }
        }
    }
}
