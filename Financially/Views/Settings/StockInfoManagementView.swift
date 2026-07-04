import SwiftUI
import SwiftData

struct StockInfoManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]
    @State private var showingAdd = false
    @State private var editingStock: StockInfo?
    @State private var editRate = ""
    @State private var isSyncing = false
    @State private var syncProgress: Double = 0
    @State private var syncTotal = 0
    @State private var syncCurrent = 0
    @State private var syncMessage = ""

    var body: some View {
        List {
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
            }

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

            if stockList.isEmpty {
                Text("No stocks added yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .navigationTitle("Stocks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAdd = true }) {
                    Label("Add", systemImage: "plus")
                }
                .disabled(isSyncing)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await syncAllPrices() } }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isSyncing || stockList.isEmpty)
            }
        }
        .sheet(isPresented: $showingAdd) {
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
    }

    private func syncAllPrices() async {
        isSyncing = true
        syncTotal = stockList.count
        syncCurrent = 0
        syncProgress = 0

        for stock in stockList {
            syncCurrent += 1
            syncMessage = "Fetching \(stock.ticker)..."
            syncProgress = Double(syncCurrent - 1)

            if let price = await fetchPrice(for: stock.ticker) {
                stock.currentRate = price
                syncRateToHoldings(ticker: stock.ticker, rate: price)
            }

            syncProgress = Double(syncCurrent)
        }

        syncMessage = "Done!"
        try? modelContext.save()
        isSyncing = false
    }

    private func fetchPrice(for ticker: String) async -> Decimal? {
        guard let url = URL(string: "https://dps.psx.com.pk/company/\(ticker)") else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            let pattern = #"quote__price.*?Rs\.\s*([\d,.]+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
                  let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html) else {
                return nil
            }

            let priceString = html[range].replacingOccurrences(of: ",", with: "")
            return Decimal(string: priceString)
        } catch {
            return nil
        }
    }

    private func syncRateToHoldings(ticker: String, rate: Decimal) {
        let fetch = FetchDescriptor<StockHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.ticker == ticker {
            holding.currentPrice = rate
            holding.priceFetchedAt = Date()
        }
    }
}

struct AddStockInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var ticker = ""
    @State private var currentRate = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
                    TextField("Company Name", text: $companyName)
                    TextField("Ticker (e.g. MEBL)", text: $ticker)
                        .textInputAutocapitalization(.characters)
                }

                Section("Current Rate") {
                    AmountField(amount: $currentRate)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New Stock")
            .formToolbar(label: "Save", isDisabled: companyName.isEmpty || ticker.isEmpty) { save() }
        }
    }

    private func save() {
        guard !companyName.isEmpty else { errorMessage = "Company name is required"; return }
        guard !ticker.isEmpty else { errorMessage = "Ticker is required"; return }

        let rate = Decimal(string: currentRate) ?? 0
        let stock = StockInfo(companyName: companyName, ticker: ticker.uppercased(), currentRate: rate)
        modelContext.insert(stock)
        dismiss()
    }
}

extension StockInfo: CustomStringConvertible {
    var description: String { "\(companyName) (\(ticker))" }
}