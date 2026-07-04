import SwiftUI
import SwiftData

struct CommodityInfoManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @State private var showingAdd = false
    @State private var editingCommodity: CommodityInfo?
    @State private var editRate = ""

    var body: some View {
        List {
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

    @State private var name = ""
    @State private var symbol = ""
    @State private var ratePerGram = ""
    @State private var errorMessage: String?

    private let presetCommodities = [
        ("Gold", "XAU"),
        ("Silver", "XAG")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Add") {
                    ForEach(presetCommodities, id: \.1) { preset in
                        Button(action: {
                            name = preset.0
                            symbol = preset.1
                        }) {
                            HStack {
                                Text(preset.0)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(preset.1)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Commodity") {
                    TextField("Name (e.g. Gold)", text: $name)
                    TextField("Symbol (e.g. XAU)", text: $symbol)
                        .textInputAutocapitalization(.characters)
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
