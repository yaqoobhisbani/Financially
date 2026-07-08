import SwiftUI
import SwiftData

struct MarketRatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]
    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @State private var selectedTab: MarketTab = .stocks
    @State private var showingAddStock = false
    @State private var editingStock: StockInfo?
    @State private var editingCommodity: CommodityInfo?
    @State private var editRate = ""
    @State private var isSyncing = false
    @State private var syncProgress: Double = 0
    @State private var syncTotal = 0
    @State private var syncCurrent = 0
    @State private var syncMessage = ""

    enum MarketTab: String, CaseIterable {
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
                case .stocks:
                    stocksSection
                case .commodities:
                    commoditiesSection
                }
            }
        }
        .navigationTitle("Market Rates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await syncAll() } }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isSyncing)
            }
            ToolbarItem(placement: .primaryAction) {
                if selectedTab == .stocks {
                    Button(action: { showingAddStock = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(isSyncing)
                }
            }
        }
        .sheet(isPresented: $showingAddStock) {
            AddStockInfoView()
        }
        .alert("Update Rate", isPresented: .init(get: { editingStock != nil }, set: { if !$0 { editingStock = nil } })) {
            TextField("Rate", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let stock = editingStock, let rate = Decimal(string: editRate), rate > 0 {
                    stock.currentRate = rate
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
                    Text(commodity.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
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
        let total = max(stockList.count + commodityList.count, 1)
        syncTotal = total
        syncCurrent = 0
        syncProgress = 0

        let service = MarketRateService(modelContext: modelContext)
        await service.syncAll { current, total, message in
            syncCurrent = current
            syncTotal = total
            syncMessage = message
            syncProgress = Double(current)
        }

        syncMessage = "Done!"
        isSyncing = false
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
