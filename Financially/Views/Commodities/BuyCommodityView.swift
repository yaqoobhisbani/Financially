import SwiftUI
import SwiftData

struct BuyCommodityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]

    @State private var selectedCommodity: CommodityInfo?
    @State private var grams = ""
    @State private var pricePerGram = ""
    @State private var brokerageFee = ""
    @State private var tax = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showCommodityPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Commodity") {
                    Button(action: { showCommodityPicker = true }) {
                        HStack {
                            VStack(alignment: .leading) {
                                if let commodity = selectedCommodity {
                                    Text(commodity.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(commodity.symbol)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select a commodity")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Trade Details") {
                    HStack {
                        Text("Grams")
                        Spacer()
                        TextField("0", text: $grams)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Price per Gram")
                        Spacer()
                        TextField("0", text: $pricePerGram)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let total = totalAmount {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(total.formattedCurrency())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Fees") {
                    HStack {
                        Text("Brokerage Fee")
                        Spacer()
                        TextField("0", text: $brokerageFee)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Tax")
                        Spacer()
                        TextField("0", text: $tax)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let net = netAmount {
                        HStack {
                            Text("Net Cost")
                            Spacer()
                            Text(net.formattedCurrency())
                                .font(.headline)
                        }
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Buy Commodity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Buy") { save() }
                        .disabled(selectedCommodity == nil || grams.isEmpty || pricePerGram.isEmpty)
                }
            }
            .sheet(isPresented: $showCommodityPicker) {
                commodityPicker
            }
        }
    }

    private var commodityPicker: some View {
        NavigationStack {
            List(commodityList) { commodity in
                Button {
                    selectedCommodity = commodity
                    pricePerGram = commodity.currentRatePerGram > 0 ? "\(commodity.currentRatePerGram)" : ""
                    showCommodityPicker = false
                } label: {
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
                                .font(.subheadline.bold())
                            Text("per gram")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Select Commodity")
        }
    }

    private var gramsValue: Decimal? { Decimal(string: grams) }
    private var priceValue: Decimal? { Decimal(string: pricePerGram) }
    private var totalAmount: Decimal? {
        guard let g = gramsValue, let p = priceValue else { return nil }
        return g * p
    }
    private var brokerageValue: Decimal { Decimal(string: brokerageFee) ?? 0 }
    private var taxValue: Decimal { Decimal(string: tax) ?? 0 }
    private var netAmount: Decimal? {
        guard let total = totalAmount else { return nil }
        return total + brokerageValue + taxValue
    }

    private func save() {
        guard let commodity = selectedCommodity else { errorMessage = "Please select a commodity"; return }
        guard let gramsVal = gramsValue, gramsVal > 0 else {
            errorMessage = "Please enter a valid number of grams"
            return
        }
        guard let price = priceValue, price > 0 else {
            errorMessage = "Please enter a valid price per gram"
            return
        }
        guard let net = netAmount, net > 0 else {
            errorMessage = "Please enter valid amounts"
            return
        }

        let holdingId = findOrCreateHolding(commodity: commodity)
        let total = gramsVal * price
        let fees = brokerageValue + taxValue

        let trade = CommodityTrade(
            holdingId: holdingId,
            type: .buy,
            commodityName: commodity.name,
            symbol: commodity.symbol,
            grams: gramsVal,
            pricePerGram: price,
            totalAmount: total,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netAmount: net,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(trade)

        updateHolding(holdingId: holdingId, grams: gramsVal, totalCost: total, fees: fees)
        try? modelContext.save()
        dismiss()
    }

    private func findOrCreateHolding(commodity: CommodityInfo) -> UUID {
        let fetch = FetchDescriptor<CommodityHolding>()
        let all = (try? modelContext.fetch(fetch)) ?? []
        if let existing = all.first(where: { $0.symbol == commodity.symbol }) {
            return existing.id
        }
        let holding = CommodityHolding(
            commodityName: commodity.name,
            symbol: commodity.symbol,
            currentPricePerGram: commodity.currentRatePerGram
        )
        modelContext.insert(holding)
        return holding.id
    }

    private func updateHolding(holdingId: UUID, grams: Decimal, totalCost: Decimal, fees: Decimal) {
        let fetch = FetchDescriptor<CommodityHolding>()
        guard let holding = (try? modelContext.fetch(fetch))?.first(where: { $0.id == holdingId }) else { return }
        let newTotalGrams = holding.totalGrams + grams
        let newCost = holding.totalCost + totalCost
        holding.totalGrams = newTotalGrams
        holding.totalCost = newCost
        holding.totalFeesPaid += fees
        holding.avgCostPerGram = newTotalGrams > 0 ? newCost / newTotalGrams : 0
    }
}
