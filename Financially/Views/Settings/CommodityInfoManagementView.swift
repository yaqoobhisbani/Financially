import SwiftUI
import SwiftData

struct CommodityInfoManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @State private var showingAdd = false
    @State private var editingCommodity: CommodityInfo?
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

            ForEach(commodityList) { commodity in
                HStack {
                    VStack(alignment: .leading) {
                        Text(commodity.name)
                            .font(.headline)
                        Text(commodity.symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(commodity.currentRatePerGram.formattedCurrency())
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCommodity = commodity
                                editRate = "\(commodity.currentRatePerGram)"
                            }
                        Text("per gram")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(commodity)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Edit Rate") {
                        editingCommodity = commodity
                        editRate = "\(commodity.currentRatePerGram)"
                    }
                    .tint(.orange)
                }
            }

            if commodityList.isEmpty {
                Text("No commodities added yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .navigationTitle("Commodities")
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
                .disabled(isSyncing || commodityList.isEmpty)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCommodityInfoView()
        }
        .alert("Update Rate", isPresented: .init(get: { editingCommodity != nil }, set: { if !$0 { editingCommodity = nil } })) {
            TextField("Rate per gram", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let commodity = editingCommodity, let rate = Decimal(string: editRate), rate > 0 {
                    commodity.currentRatePerGram = rate
                    syncRateToHoldings(symbol: commodity.symbol, rate: rate)
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

    private func syncAllPrices() async {
        isSyncing = true
        syncTotal = commodityList.count
        syncCurrent = 0
        syncProgress = 0

        for commodity in commodityList {
            syncCurrent += 1
            syncMessage = "Fetching \(commodity.symbol)..."
            syncProgress = Double(syncCurrent - 1)

            let price: Decimal?
            switch commodity.symbol.uppercased() {
            case "XAU":
                price = await fetchGoldPrice()
            case "XAG":
                price = await fetchSilverPrice()
            default:
                price = nil
            }

            if let price {
                commodity.currentRatePerGram = price
                syncRateToHoldings(symbol: commodity.symbol, rate: price)
            }

            syncProgress = Double(syncCurrent)
        }

        syncMessage = "Done!"
        try? modelContext.save()
        isSyncing = false
    }

    private func fetchGoldPrice() async -> Decimal? {
        guard let url = URL(string: "https://beta-restapi.sarmaaya.pk/api/commodities/goldRates") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let response = json?["response"] as? [String: Any],
                  let perGram = response["perGram"] as? [String: Any],
                  let rate = perGram["24k"] as? NSNumber else { return nil }
            return Decimal(string: "\(rate)")
        } catch {
            return nil
        }
    }

    private func fetchSilverPrice() async -> Decimal? {
        guard let url = URL(string: "https://beta-restapi.sarmaaya.pk/api/commodities/xag") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let response = json?["response"] as? [[String: Any]],
                  let first = response.first,
                  let rate = first["price1g"] as? NSNumber else { return nil }
            return Decimal(string: "\(rate)")
        } catch {
            return nil
        }
    }

    private func syncRateToHoldings(symbol: String, rate: Decimal) {
        let fetch = FetchDescriptor<CommodityHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.symbol == symbol {
            holding.currentPricePerGram = rate
            holding.priceFetchedAt = Date()
        }
    }
}

struct AddCommodityInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset = 0
    @State private var name = ""
    @State private var symbol = ""
    @State private var ratePerGram = ""
    @State private var errorMessage: String?

    private let presets: [(name: String, symbol: String)] = [
        ("Gold", "XAU"),
        ("Silver", "XAG")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Commodity", selection: $selectedPreset) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { _, preset in
                            Text(preset.name).tag(presets.firstIndex(where: { $0.symbol == preset.symbol }) ?? 0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPreset) { _, newValue in
                        guard presets.indices.contains(newValue) else { return }
                        name = presets[newValue].name
                        symbol = presets[newValue].symbol
                    }
                }

                Section("Commodity Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Commodity name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Symbol")
                        Spacer()
                        TextField("e.g. XAU", text: $symbol)
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Rate") {
                    AmountField(amount: $ratePerGram, suffix: "/ gram")
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New Commodity")
            .formToolbar(label: "Save", isDisabled: name.isEmpty || symbol.isEmpty) { save() }
        }
    }

    private func save() {
        guard !name.isEmpty else { errorMessage = "Name is required"; return }
        guard !symbol.isEmpty else { errorMessage = "Symbol is required"; return }

        let rate = Decimal(string: ratePerGram) ?? 0
        let commodity = CommodityInfo(name: name, symbol: symbol.uppercased(), currentRatePerGram: rate)
        modelContext.insert(commodity)
        dismiss()
    }
}
