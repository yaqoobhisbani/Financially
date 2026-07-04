import SwiftUI
import SwiftData

struct CommodityDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var allHoldings: [CommodityHolding]
    @State private var showBuy = false
    @State private var showSell = false

    private var holdings: [CommodityHolding] {
        allHoldings.filter { $0.totalGrams > 0 }
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
        }
        .navigationTitle("Commodities")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBuy) { BuyCommodityView() }
        .sheet(isPresented: $showSell) { SellCommodityView() }
    }

    // MARK: - Balance

    private var balanceSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Portfolio")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalHoldingValue.formattedCurrency())
                            .font(.title.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("P&L")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalUnrealizedPAndL.formattedCurrency())
                            .font(.title3.bold())
                            .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Holdings Value")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalHoldingValue.formattedCurrency())
                            .font(.body.bold())
                            .foregroundStyle(.incomeGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Total Cost")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalCostBasis.formattedCurrency())
                            .font(.body.bold())
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Return")
                            .font(.caption).foregroundStyle(.secondary)
                        PercentageText(value: totalPAndLPercentage)
                            .font(.body.bold())
                            .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            HStack(spacing: 10) {
                actionCard("Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuy = true }
                actionCard("Sell", icon: "minus.circle.fill", color: .expenseRed) { showSell = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Text("Actions")
        }
    }

    private func actionCard(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Holdings

    private var holdingsSection: some View {
        Section("Holdings") {
            if holdings.isEmpty {
                Text("No holdings yet. Buy commodities to get started.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            ForEach(holdings) { holding in
                NavigationLink(destination: CommodityHoldingDetailView(holding: holding)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.commodityName)
                                .font(.headline)
                            Text(holding.symbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
