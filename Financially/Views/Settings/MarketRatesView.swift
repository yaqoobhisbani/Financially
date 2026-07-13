import SwiftUI
import SwiftData

struct MarketRatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]
    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @Query(sort: \MutualFundScheme.schemeName) private var mfSchemeList: [MutualFundScheme]
    @State private var selectedTab: MarketTab = .mutualFunds
    @State private var showingAddStock = false
    @State private var showingAddMFScheme = false
    @State private var editingStock: StockInfo?
    @State private var editingCommodity: CommodityInfo?
    @State private var editingMFScheme: MutualFundScheme?
    @State private var editRate = ""
    @State private var isSyncing = false
    @State private var syncProgress: Double = 0
    @State private var syncTotal = 0
    @State private var syncCurrent = 0
    @State private var syncMessage = ""

    enum MarketTab: String, CaseIterable {
        case mutualFunds = "Mutual Funds"
        case stocks = "Stocks"
        case commodities = "Commodities"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Market", selection: $selectedTab) {
                ForEach(MarketTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if isSyncing {
                Section {
                    VStack(spacing: 8) {
                        ProgressView(value: syncProgress, total: Double(syncTotal))
                        Text(syncMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(syncCurrent) of \(syncTotal)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }

            List {
                switch selectedTab {
                case .mutualFunds:
                    mutualFundsSection
                case .stocks:
                    stocksSection
                case .commodities:
                    commoditiesSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .groupedScreenBackground()
        .navigationTitle("Market Rates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await syncAll() } }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isSyncing)
            }
            ToolbarItem(placement: .primaryAction) {
                switch selectedTab {
                case .mutualFunds:
                    Button(action: { showingAddMFScheme = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(isSyncing)
                case .stocks:
                    Button(action: { showingAddStock = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(isSyncing)
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showingAddStock) {
            AddStockInfoView()
        }
        .sheet(isPresented: $showingAddMFScheme) {
            AddMFSchemeView()
        }
        .alert("Update Rate", isPresented: .init(get: { editingStock != nil }, set: { if !$0 { editingStock = nil } })) {
            TextField("Rate", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let stock = editingStock, let rate = Decimal(string: editRate), rate > 0 {
                    stock.currentRate = rate
                    stock.lastUpdatedAt = Date()
                    syncRateToHoldings(ticker: stock.ticker, rate: rate)
                }
                editingStock = nil
            }
            Button("Cancel", role: .cancel) { editingStock = nil }
        } message: {
            if let stock = editingStock {
                Text("Update rate for \(stock.ticker)")
            }
        }
        .alert("Update Rate", isPresented: .init(get: { editingCommodity != nil }, set: { if !$0 { editingCommodity = nil } })) {
            TextField("Rate per gram", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let commodity = editingCommodity, let rate = Decimal(string: editRate), rate > 0 {
                    commodity.currentRatePerGram = rate
                    commodity.lastUpdatedAt = Date()
                    syncRateToHoldings(commodityName: commodity.name, rate: rate)
                    try? modelContext.save()
                }
                editingCommodity = nil
            }
            Button("Cancel", role: .cancel) { editingCommodity = nil }
        } message: {
            if let commodity = editingCommodity {
                Text("Update rate per gram for \(commodity.name)")
            }
        }
        .alert("Update NAV", isPresented: .init(get: { editingMFScheme != nil }, set: { if !$0 { editingMFScheme = nil } })) {
            TextField("NAV Price", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let scheme = editingMFScheme, let rate = Decimal(string: editRate), rate > 0 {
                    scheme.navPrice = rate
                    scheme.lastUpdatedAt = Date()
                    let service = MarketRateService(modelContext: modelContext)
                    service.syncMFToHoldings(fundCode: scheme.fundCode, navPrice: rate)
                    try? modelContext.save()
                }
                editingMFScheme = nil
            }
            Button("Cancel", role: .cancel) { editingMFScheme = nil }
        } message: {
            if let scheme = editingMFScheme {
                Text("Update NAV for \(scheme.schemeName)")
            }
        }
    }

    @ViewBuilder
    private var mutualFundsSection: some View {
        if mfSchemeList.isEmpty {
            Text("No schemes added yet")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ForEach(mfSchemeList) { scheme in
                HStack {
                    VStack(alignment: .leading) {
                        Text(scheme.schemeName)
                            .font(.headline)
                        Text(scheme.fundCode)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let fundHouse = scheme.fundHouse {
                            Text(fundHouse)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        if let lastUpdated = scheme.lastUpdatedAt {
                            Text(lastUpdated, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(scheme.navPrice.formattedNAVPrice())
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingMFScheme = scheme
                                editRate = "\(scheme.navPrice)"
                            }
                        Text("per unit")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(scheme)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Edit NAV") {
                        editingMFScheme = scheme
                        editRate = "\(scheme.navPrice)"
                    }
                    .tint(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var stocksSection: some View {
        if stockList.isEmpty {
            Text("No stocks added yet")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ForEach(stockList) { stock in
                HStack {
                    VStack(alignment: .leading) {
                        Text(stock.companyName)
                            .font(.headline)
                        Text(stock.ticker)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let lastUpdated = stock.lastUpdatedAt {
                            Text(lastUpdated, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(stock.currentRate.formattedCurrency())
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingStock = stock
                                editRate = "\(stock.currentRate)"
                            }
                        Text("per share")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(stock)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Edit Rate") {
                        editingStock = stock
                        editRate = "\(stock.currentRate)"
                    }
                    .tint(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var commoditiesSection: some View {
        if commodityList.isEmpty {
            Text("No commodities available")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ForEach(commodityList) { commodity in
                HStack {
                    VStack(alignment: .leading) {
                        Text(commodity.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let lastUpdated = commodity.lastUpdatedAt {
                            Text(lastUpdated, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Button {
                            editingCommodity = commodity
                            editRate = "\(commodity.currentRatePerGram)"
                        } label: {
                            Text(commodity.currentRatePerGram.formattedCurrency())
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        Text("per gram")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private func syncAll() async {
        isSyncing = true
        let baseTotal = stockList.count + commodityList.count
        let mfTotal = mfSchemeList.count
        let total = max(baseTotal + mfTotal, 1)
        syncTotal = total
        syncCurrent = 0
        syncProgress = 0

        let service = MarketRateService(modelContext: modelContext)

        if baseTotal > 0 {
            await service.syncAll { current, total, message in
                syncCurrent = current
                syncTotal = total + mfTotal
                syncMessage = message
                syncProgress = Double(current)
            }
        }

        if mfTotal > 0 {
            syncMessage = "Fetching mutual fund NAVs..."
            syncCurrent = baseTotal
            syncProgress = Double(baseTotal)
            let allNavs = await service.fetchAllMFNavs()
            await MainActor.run {
                syncMFSchemes(service: service, allNavs: allNavs)
                syncCurrent = total
                syncProgress = Double(total)
            }
        }

        syncMessage = "Done!"
        isSyncing = false
    }

    @MainActor
    private func syncMFSchemes(service: MarketRateService, allNavs: [String: Decimal]) {
        let remaining = mfSchemeList.count
        var current = 0

        for scheme in mfSchemeList {
            current += 1
            syncMessage = "Syncing \(scheme.schemeName)..."
            syncCurrent = syncTotal - remaining + current
            syncProgress = Double(syncCurrent)

            let matched = allNavs.first { name, _ in
                name.localizedCaseInsensitiveContains(scheme.schemeName) || scheme.schemeName.localizedCaseInsensitiveContains(name)
            }

            if let navPrice = matched?.value {
                scheme.navPrice = navPrice
                scheme.lastUpdatedAt = Date()
                service.syncMFToHoldings(fundCode: scheme.fundCode, navPrice: navPrice)
            }
        }

        try? modelContext.save()
    }

    private func syncRateToHoldings(ticker: String, rate: Decimal) {
        let fetch = FetchDescriptor<StockHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.ticker == ticker {
            holding.currentPrice = rate
            holding.priceFetchedAt = Date()
        }
    }

    private func syncRateToHoldings(commodityName: String, rate: Decimal) {
        let symbol = commodityName.localizedCaseInsensitiveContains("gold") ? "XAU" : "XAG"
        let fetch = FetchDescriptor<CommodityHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.symbol == symbol {
            holding.currentPricePerGram = rate
            holding.priceFetchedAt = Date()
        }
    }
}
