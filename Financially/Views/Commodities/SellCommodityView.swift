import SwiftUI
import SwiftData

struct SellCommodityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedHolding: CommodityHolding?
    @State private var grams = ""
    @State private var pricePerGram = ""
    @State private var brokerageFee = ""
    @State private var tax = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showHoldingPicker = false

    @Query private var holdings: [CommodityHolding]

    private var activeHoldings: [CommodityHolding] {
        holdings.filter { $0.totalGrams > 0 }
    }

    private var availableGrams: Decimal { selectedHolding?.totalGrams ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Holding") {
                    Button(action: { showHoldingPicker = true }) {
                        HStack {
                            Text("Commodity")
                            Spacer()
                            if let h = selectedHolding {
                                Text("\(h.commodityName) (\(h.totalGrams.formattedNumber()) g)")
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select holding")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Trade Details") {
                    HStack {
                        Text("Grams to Sell")
                        Spacer()
                        TextField("0", text: $grams)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let h = selectedHolding, let g = Decimal(string: grams), g > availableGrams {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Only \(availableGrams.formattedNumber()) grams available")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    HStack {
                        Text("Price per Gram")
                        Spacer()
                        TextField("0", text: $pricePerGram)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let total = saleAmount {
                        HStack {
                            Text("Total Sale")
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
                    if let net = netProceeds {
                        HStack {
                            Text("Net Proceeds")
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
            .navigationTitle("Sell Commodity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sell") { save() }
                        .disabled(selectedHolding == nil || grams.isEmpty || pricePerGram.isEmpty)
                }
            }
            .sheet(isPresented: $showHoldingPicker) {
                holdingPicker
            }
        }
    }

    private var holdingPicker: some View {
        NavigationStack {
            List(activeHoldings) { holding in
                Button {
                    selectedHolding = holding
                    showHoldingPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(holding.commodityName)
                                .font(.headline)
                            Text(holding.symbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(holding.totalGrams.formattedNumber()) g")
                            Text(holding.totalCost.formattedCurrency())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Holding")
        }
    }

    private var gramsValue: Decimal? { Decimal(string: grams) }
    private var priceValue: Decimal? { Decimal(string: pricePerGram) }
    private var saleAmount: Decimal? {
        guard let g = gramsValue, let p = priceValue else { return nil }
        return g * p
    }
    private var brokerageValue: Decimal { Decimal(string: brokerageFee) ?? 0 }
    private var taxValue: Decimal { Decimal(string: tax) ?? 0 }
    private var netProceeds: Decimal? {
        guard let total = saleAmount else { return nil }
        return total - brokerageValue - taxValue
    }

    private func save() {
        guard let holding = selectedHolding else {
            errorMessage = "Please select a holding"
            return
        }
        guard let gramsVal = gramsValue, gramsVal > 0 else {
            errorMessage = "Please enter a valid number of grams"
            return
        }
        guard gramsVal <= holding.totalGrams else {
            errorMessage = "Cannot sell more grams than you hold"
            return
        }
        guard let price = priceValue, price > 0 else {
            errorMessage = "Please enter a valid price per gram"
            return
        }
        guard let proceeds = netProceeds, proceeds > 0 else {
            errorMessage = "Net proceeds must be positive"
            return
        }

        let total = gramsVal * price
        let fees = brokerageValue + taxValue

        let trade = CommodityTrade(
            holdingId: holding.id,
            type: .sell,
            commodityName: holding.commodityName,
            symbol: holding.symbol,
            grams: gramsVal,
            pricePerGram: price,
            totalAmount: total,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netAmount: proceeds,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(trade)

        let remainingGrams = holding.totalGrams - gramsVal
        if remainingGrams == 0 {
            holding.totalGrams = 0
            holding.totalCost = 0
            holding.avgCostPerGram = 0
        } else {
            let avgCostPerGram = holding.totalCost / holding.totalGrams
            holding.totalCost -= gramsVal * avgCostPerGram
            holding.totalGrams = remainingGrams
            holding.avgCostPerGram = holding.totalGrams > 0
                ? holding.totalCost / holding.totalGrams
                : 0
        }
        holding.totalFeesPaid += fees

        try? modelContext.save()
        dismiss()
    }
}
