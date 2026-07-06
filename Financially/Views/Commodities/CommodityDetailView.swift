import SwiftUI
import SwiftData

struct CommodityDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var allHoldings: [CommodityHolding]
    @Query private var allTransactions: [Transaction]
    @State private var showBuy = false
    @State private var showSell = false
    @State private var selectedTransaction: Transaction?

    private var holdings: [CommodityHolding] {
        allHoldings.filter { $0.totalGrams > 0 }
    }

    private var commodityTransactions: [Transaction] {
        allTransactions
            .filter { $0.type == .commodityBuy || $0.type == .commoditySell }
            .sorted { $0.date > $1.date }
    }

    private var totalHoldingValue: Decimal {
        holdings.reduce(0) { $0 + $1.currentValue }
    }

    private var totalCostBasis: Decimal {
        holdings.reduce(0) { $0 + $1.totalCost }
    }

    private var totalUnrealizedPAndL: Decimal {
        holdings.reduce(0) { $0 + $1.unrealizedPAndL }
    }

    private var totalPAndLPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPAndL / totalCostBasis) * 100
    }

    var body: some View {
        List {
            balanceSection
            actionsSection
            holdingsSection
            recentTransactionsSection
        }
        .navigationTitle("Commodities")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBuy) { BuyCommodityView() }
        .sheet(isPresented: $showSell) { SellCommodityView() }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack { TransactionDetailView(transaction: tx) }
        }
    }

    // MARK: - Balance

    private var balanceSection: some View {
        Section {
            SummaryBalanceView(
                heroLeftLabel: "Total Portfolio",
                heroLeftValue: totalHoldingValue.formattedCurrency(),
                heroRightLabel: "P&L",
                heroRightValue: totalUnrealizedPAndL.formattedCurrency(),
                heroRightColor: totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed,
                detailRows: [
                    [
                        AnyView(SummaryMetric(label: "Holdings Value", value: totalHoldingValue.formattedCurrency(), color: .incomeGreen)),
                        AnyView(SummaryMetric(label: "Total Cost", value: totalCostBasis.formattedCurrency(), alignment: .trailing))
                    ],
                    [
                        AnyView(SummaryMetricView(label: "Return") { PercentageText(value: totalPAndLPercentage).foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed) })
                    ]
                ]
            )
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            HStack(spacing: 10) {
                ActionCard(label: "Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuy = true }
                ActionCard(label: "Sell", icon: "minus.circle.fill", color: .expenseRed) { showSell = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Text("Actions")
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        Section("Recent Transactions") {
            ForEach(Array(commodityTransactions.prefix(20))) { tx in
                TransactionRowView(transaction: tx, showIcon: true)
                .contentShape(Rectangle())
                .onTapGesture { selectedTransaction = tx }
            }

            if commodityTransactions.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        }
    }

    // MARK: - Holdings

    private var holdingsSection: some View {
        Section("Holdings") {
            if holdings.isEmpty {
                EmptyStateView(title: "No holdings yet", systemImage: "diamond.fill", description: "Buy commodities to get started")
            }
            ForEach(holdings) { holding in
                NavigationLink(destination: CommodityHoldingDetailView(holding: holding)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.commodityName)
                                .font(.headline)
                            HStack(spacing: 4) {
                                Text("\(holding.totalGrams.formattedNumber()) g")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("@")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(holding.avgCostPerGram.formattedCurrency())
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
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
}
