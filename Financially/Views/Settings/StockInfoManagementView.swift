import SwiftUI
import SwiftData

struct StockInfoManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]
    @State private var showingAdd = false
    @State private var editingStock: StockInfo?
    @State private var editRate = ""

    var body: some View {
        List {
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
                        Button {
                            editingStock = stock
                            editRate = "\(stock.currentRate)"
                        } label: {
                            Text(stock.currentRate.formattedCurrency())
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
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
            ToolbarItem {
                Button(action: { showingAdd = true }) {
                    Label("Add", systemImage: "plus")
                }
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
                    HStack {
                        Text("PKR")
                        TextField("0", text: $currentRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("New Stock")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(companyName.isEmpty || ticker.isEmpty)
                }
            }
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