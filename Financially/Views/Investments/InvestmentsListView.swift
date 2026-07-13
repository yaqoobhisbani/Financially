import SwiftUI
import SwiftData

struct InvestmentsListView: View {
    @Query private var accounts: [Account]
    @Query private var allHoldings: [StockHolding]
    @Query private var allCommodityHoldings: [CommodityHolding]
    @Query private var allMFHoldings: [MutualFundHolding]
    @Query private var allTransactions: [Transaction]

    @State private var selectedSegment: InvestmentSegment
    @State private var showCreatePSX = false
    @State private var showBuyCommodity = false
    @State private var showSellCommodity = false
    @State private var showCreateMF = false
    @State private var selectedTransaction: Transaction?
    @State private var showCommodityStatement = false

    enum InvestmentSegment: String, CaseIterable {
        case mutualFunds = "Mutual Funds"
        case psx = "PSX"
        case commodities = "Commodities"
    }

    init(initialSegment: InvestmentSegment = .mutualFunds) {
        _selectedSegment = State(initialValue: initialSegment)
    }

    private var psxAccounts: [Account] {
        accounts.filter { $0.accountType == .psx }
    }

    private var mfAccounts: [Account] {
        accounts.filter { $0.accountType == .mutualFund }
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
                GlassSegmentedControl(options: InvestmentSegment.allCases, selection: $selectedSegment) { $0.rawValue }
                    .padding()

                switch selectedSegment {
                case .mutualFunds:
                    mutualFundsSection
                case .psx:
                    psxSection
                case .commodities:
                    commoditiesSection
                }
            }
            .groupedScreenBackground()
            .navigationTitle("Investments")
            .toolbar {
                if selectedSegment == .commodities {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showCommodityStatement = true }) {
                            Image(systemName: "doc.text")
                        }
                        .tint(.primary)
                        .accessibilityLabel("View Statement")
                    }
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        switch selectedSegment {
                        case .mutualFunds: showCreateMF = true
                        case .psx: showCreatePSX = true
                        case .commodities: showBuyCommodity = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .tint(.primary)
                    .accessibilityLabel("Add")
                }
            }
            .sheet(isPresented: $showCreatePSX) {
                CreatePSXAccountView()
            }
            .sheet(isPresented: $showCommodityStatement) {
                CommodityStatementView()
            }
            .sheet(isPresented: $showCreateMF) {
                CreateMFAccountView()
            }
        }
    }

    // MARK: - PSX Section

    private var psxSection: some View {
        List {
            if psxAccounts.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No PSX Accounts",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: "Create a PSX account to track your stock investments and portfolio",
                        buttonLabel: "Add PSX Account",
                        action: { showCreatePSX = true }
                    )
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
        .scrollContentBackground(.hidden)
    }

    // MARK: - Commodities Section

    private var commoditiesSection: some View {
        List {
            commoditiesBalanceSection
            commoditiesActionsSection

            if activeCommodityHoldings.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No Commodities",
                        systemImage: "diamond.fill",
                        description: "Buy gold or silver to start tracking your physical commodity holdings"
                    )
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

            commodityTransactionsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showBuyCommodity) { BuyCommodityView() }
        .sheet(isPresented: $showSellCommodity) { SellCommodityView() }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack { TransactionDetailView(transaction: tx) }
        }
    }

    // MARK: - Mutual Funds Section

    private var mutualFundsSection: some View {
        List {
            if mfAccounts.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No Mutual Fund Accounts",
                        systemImage: "chart.pie.fill",
                        description: "Create a mutual fund account to track your investments in schemes",
                        buttonLabel: "Add MF Account",
                        action: { showCreateMF = true }
                    )
                }
            } else {
                ForEach(mfAccounts) { account in
                    let holdings = allMFHoldings.filter { $0.accountId == account.id && $0.totalUnits > 0 }
                    NavigationLink(destination: MFAccountDetailView(account: account)) {
                        MFAccountRowView(account: account, holdings: holdings)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var commodityTransactionsSection: some View {
        let txs = allTransactions
            .filter { $0.type == .commodityBuy || $0.type == .commoditySell }
            .sorted { $0.date > $1.date }
        return Section {
            ForEach(Array(txs.prefix(5))) { tx in
                TransactionRowView(transaction: tx, showIcon: true)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTransaction = tx }
            }

            if txs.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        } header: {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button("View All") { showCommodityStatement = true }
                    .font(.subheadline)
            }
            .listRowInsets(EdgeInsets())
        }
    }

    private var commoditiesBalanceSection: some View {
        Section {
            SummaryBalanceView(
                heroLeftLabel: "Total Portfolio",
                heroLeftValue: totalHoldingValue.formattedCurrency(),
                detailRows: [
                    [
                        AnyView(SummaryMetric(label: "Holdings Value", value: totalHoldingValue.formattedCurrency(), color: .incomeGreen)),
                        AnyView(SummaryMetric(label: "P&L", value: totalUnrealizedPAndL.formattedCurrency(), color: totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed, alignment: .trailing))
                    ],
                    [
                        AnyView(SummaryMetricView(label: "Return") { PercentageText(value: totalPAndLPercentage).foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed) }),
                        AnyView(SummaryMetric(label: "Total Cost", value: totalCostBasis.formattedCurrency(), alignment: .trailing))
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
                    .tabularNumbers()
                    .fixedSize(horizontal: true, vertical: false)
                Text(psxProfitLoss.formattedCurrency(currency: account.currency))
                    .font(.caption)
                    .tabularNumbers()
                    .foregroundStyle(psxProfitLoss >= 0 ? .gain : .loss)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .opacity(account.isActive ? 1 : 0.5)
    }
}

// MARK: - Commodity Row

// MARK: - MF Account Row

struct MFAccountRowView: View {
    let account: Account
    let holdings: [MutualFundHolding]

    private var portfolioValue: Decimal {
        holdings.reduce(0) { $0 + $1.currentValue }
    }

    private var totalCost: Decimal {
        holdings.reduce(0) { $0 + $1.totalCost }
    }

    private var profitLoss: Decimal {
        portfolioValue - totalCost
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(account.fundHouse ?? "MF Account")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(portfolioValue.formattedCurrency())
                    .font(.headline)
                    .tabularNumbers()
                    .fixedSize(horizontal: true, vertical: false)
                Text(profitLoss.formattedCurrency())
                    .font(.caption)
                    .tabularNumbers()
                    .foregroundStyle(profitLoss >= 0 ? .gain : .loss)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .opacity(account.isActive ? 1 : 0.5)
    }
}

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
                    .tabularNumbers()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(holding.unrealizedPAndL.formattedCurrency())
                    .font(.caption)
                    .tabularNumbers()
                    .foregroundStyle(holding.unrealizedPAndL >= 0 ? .gain : .loss)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
