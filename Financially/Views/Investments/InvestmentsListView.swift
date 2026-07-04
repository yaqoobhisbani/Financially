import SwiftUI
import SwiftData

struct InvestmentsListView: View {
    @Query private var accounts: [Account]
    @Query private var allHoldings: [StockHolding]
    @Query private var allCommodityHoldings: [CommodityHolding]

    @State private var selectedSegment: InvestmentSegment = .psx
    @State private var showCreatePSX = false
    @State private var showBuyCommodity = false
    @State private var showSellCommodity = false

    private enum InvestmentSegment: String, CaseIterable {
        case psx = "PSX"
        case commodities = "Commodities"
    }

    private var psxAccounts: [Account] {
        accounts.filter { $0.accountType == .psx }
    }

    private var activeCommodityHoldings: [CommodityHolding] {
        allCommodityHoldings.filter { $0.totalGrams > 0 }
    }

    private var totalHoldingValue: Decimal {
        activeCommodityHoldings.reduce(0) { $0 + $1.currentValue }
    }

    private var totalCostBasis: Decimal {
        activeCommodityHoldings.reduce(0) { $0 + $1.totalCost }
    }

    private var totalUnrealizedPAndL: Decimal {
        activeCommodityHoldings.reduce(0) { $0 + $1.unrealizedPAndL }
    }

    private var totalPAndLPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPAndL / totalCostBasis) * 100
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Segment", selection: $selectedSegment) {
                    ForEach(InvestmentSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSegment {
                case .psx:
                    psxSection
                case .commodities:
                    commoditiesSection
                }
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        if selectedSegment == .psx {
                            showCreatePSX = true
                        } else {
                            showBuyCommodity = true
                        }
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePSX) {
                CreateAccountView(allowedTypes: [.psx])
            }
        }
    }

    // MARK: - PSX Section

    private var psxSection: some View {
        List {
            if psxAccounts.isEmpty {
                Text("No PSX accounts yet. Tap + to create one.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            ForEach(psxAccounts) { account in
                NavigationLink(destination: AccountDetailView(account: account)) {
                    PSXAccountRowView(account: account, holdings: allHoldings)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Commodities Section

    private var commoditiesSection: some View {
        List {
            commoditiesBalanceSection
            commoditiesActionsSection

            if activeCommodityHoldings.isEmpty {
                Text("No commodities yet. Buy gold or silver to get started.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Section("Holdings") {
                    ForEach(activeCommodityHoldings) { holding in
                        NavigationLink(destination: CommodityHoldingDetailView(holding: holding)) {
                            CommodityRowView(holding: holding)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showBuyCommodity) { BuyCommodityView() }
        .sheet(isPresented: $showSellCommodity) { SellCommodityView() }
    }

    private var commoditiesBalanceSection: some View {
        Section {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Portfolio")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(totalHoldingValue.formattedCurrency())
                        .font(.title.bold())
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Holdings Value")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalHoldingValue.formattedCurrency())
                            .font(.body.bold())
                            .foregroundStyle(.incomeGreen)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("P&L")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalUnrealizedPAndL.formattedCurrency())
                            .font(.body.bold())
                            .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                            .lineLimit(1)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Return")
                            .font(.caption).foregroundStyle(.secondary)
                        PercentageText(value: totalPAndLPercentage)
                            .font(.body.bold())
                            .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total Cost")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(totalCostBasis.formattedCurrency())
                            .font(.body.bold())
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var commoditiesActionsSection: some View {
        Section {
            HStack(spacing: 10) {
                commodityActionCard("Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuyCommodity = true }
                commodityActionCard("Sell", icon: "minus.circle.fill", color: .expenseRed) { showSellCommodity = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func commodityActionCard(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
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
}

// MARK: - PSX Account Row

struct PSXAccountRowView: View {
    let account: Account
    let holdings: [StockHolding]

    private var psxHoldings: [StockHolding] {
        holdings.filter { $0.accountId == account.id }
    }

    private var psxPortfolioValue: Decimal {
        psxHoldings.reduce(0) { $0 + $1.currentValue }
    }

    private var psxTotalCost: Decimal {
        psxHoldings.reduce(0) { $0 + $1.totalCost }
    }

    private var psxProfitLoss: Decimal {
        psxPortfolioValue - psxTotalCost
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("PSXLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(account.brokerName ?? "PSX Account")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                let totalValue = account.currentBalance + psxPortfolioValue
                Text(totalValue.formattedCurrency(currency: account.currency))
                    .font(.headline)
                    .fixedSize(horizontal: true, vertical: false)
                Text(psxProfitLoss.formattedCurrency(currency: account.currency))
                    .font(.caption)
                    .foregroundStyle(psxProfitLoss >= 0 ? .incomeGreen : .expenseRed)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .opacity(account.isActive ? 1 : 0.5)
    }
}

// MARK: - Commodity Row

struct CommodityRowView: View {
    let holding: CommodityHolding

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "diamond.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.commodityName)
                    .font(.headline)
                Text("\(holding.totalGrams.formattedNumber()) g @ \(holding.avgCostPerGram.formattedCurrency())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.currentValue.formattedCurrency())
                    .font(.headline)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(holding.unrealizedPAndL.formattedCurrency())
                    .font(.caption)
                    .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
