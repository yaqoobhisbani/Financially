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
                CreatePSXAccountView()
            }
        }
    }

    // MARK: - PSX Section

    private var psxSection: some View {
        List {
            if psxAccounts.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image("PSXLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("No PSX Accounts")
                            .font(.headline)
                        Text("Create a PSX account to track your stock investments and portfolio")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add PSX Account") {
                            showCreatePSX = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(psxAccounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        PSXAccountRowView(account: account, holdings: allHoldings)
                    }
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
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Commodities")
                            .font(.headline)
                        Text("Buy gold or silver to start tracking your physical commodity holdings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
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
            SummaryBalanceView(
                heroLeftLabel: "Total Portfolio",
                heroLeftValue: totalHoldingValue.formattedCurrency(),
                detailRows: [
                    [
                        AnyView(SummaryMetric(label: "Holdings Value", value: totalHoldingValue.formattedCurrency(), color: .incomeGreen)),
                        AnyView(SummaryMetric(label: "P&L", value: totalUnrealizedPAndL.formattedCurrency(), color: totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed))
                    ],
                    [
                        AnyView(SummaryMetricView(label: "Return") { PercentageText(value: totalPAndLPercentage).foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed) }),
                        AnyView(SummaryMetric(label: "Total Cost", value: totalCostBasis.formattedCurrency()))
                    ]
                ]
            )
        }
    }

    private var commoditiesActionsSection: some View {
        Section {
            HStack(spacing: 10) {
                ActionCard(label: "Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuyCommodity = true }
                ActionCard(label: "Sell", icon: "minus.circle.fill", color: .expenseRed) { showSellCommodity = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
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
