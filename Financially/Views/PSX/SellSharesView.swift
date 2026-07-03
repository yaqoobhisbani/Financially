import SwiftUI
import SwiftData

struct SellSharesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var selectedHolding: StockHolding?
    @State private var shares = ""
    @State private var pricePerShare = ""
    @State private var brokerageFee = ""
    @State private var tax = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showHoldingPicker = false

    @Query private var holdings: [StockHolding]

    private var accountHoldings: [StockHolding] {
        holdings.filter { $0.accountId == account.id && $0.totalShares > 0 }
    }

    private var availableShares: Int { selectedHolding?.totalShares ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Holding") {
                    Button(action: { showHoldingPicker = true }) {
                        HStack {
                            Text("Company")
                            Spacer()
                            if let h = selectedHolding {
                                Text("\(h.ticker) (\(h.totalShares) shares)")
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
                        Text("Shares to Sell")
                        Spacer()
                        TextField("0", text: $shares)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let h = selectedHolding, let s = Int(shares), s > availableShares {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Only \(availableShares) shares available")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    HStack {
                        Text("Price per Share")
                        Spacer()
                        TextField("0", text: $pricePerShare)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let total = saleAmount {
                        HStack {
                            Text("Total Sale")
                            Spacer()
                            Text(total.formattedCurrency(currency: account.currency))
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
                            Text(net.formattedCurrency(currency: account.currency))
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
            .navigationTitle("Sell Shares")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sell") { save() }
                        .disabled(selectedHolding == nil || shares.isEmpty || pricePerShare.isEmpty)
                }
            }
            .sheet(isPresented: $showHoldingPicker) {
                holdingPicker
            }
        }
    }

    private var holdingPicker: some View {
        NavigationStack {
            List(accountHoldings) { holding in
                Button {
                    selectedHolding = holding
                    showHoldingPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(holding.companyName)
                                .font(.headline)
                            Text(holding.ticker)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(holding.totalShares) shares")
                            Text(holding.totalCost.formattedCurrency(currency: account.currency))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Holding")
        }
    }

    private var sharesValue: Int? { Int(shares) }
    private var priceValue: Decimal? { Decimal(string: pricePerShare) }
    private var saleAmount: Decimal? {
        guard let s = sharesValue, let p = priceValue else { return nil }
        return Decimal(s) * p
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
        guard let shares = sharesValue, shares > 0 else {
            errorMessage = "Please enter a valid number of shares"
            return
        }
        guard shares <= holding.totalShares else {
            errorMessage = "Cannot sell more shares than you hold"
            return
        }
        guard let price = priceValue, price > 0 else {
            errorMessage = "Please enter a valid price per share"
            return
        }
        guard let proceeds = netProceeds, proceeds > 0 else {
            errorMessage = "Net proceeds must be positive"
            return
        }

        let total = Decimal(shares) * price
        let fees = brokerageValue + taxValue

        let trade = StockTrade(
            accountId: account.id,
            holdingId: holding.id,
            type: .sell,
            ticker: holding.ticker,
            companyName: holding.companyName,
            shares: shares,
            pricePerShare: price,
            totalAmount: total,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netAmount: proceeds,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(trade)

        let remainingShares = holding.totalShares - shares
        if remainingShares == 0 {
            holding.totalShares = 0
            holding.totalCost = 0
            holding.avgCostPerShare = 0
        } else {
            let avgCostPerShare = holding.totalCost / Decimal(holding.totalShares)
            holding.totalCost -= Decimal(shares) * avgCostPerShare
            holding.totalShares = remainingShares
            holding.avgCostPerShare = holding.totalShares > 0
                ? holding.totalCost / Decimal(holding.totalShares)
                : 0
        }
        holding.totalFeesPaid += fees

        account.currentBalance += proceeds
        syncAccountFromHoldings()
        account.updatedAt = Date()

        dismiss()
    }

    private func syncAccountFromHoldings() {
        let fetch = FetchDescriptor<StockHolding>()
        guard let all = try? modelContext.fetch(fetch) else { return }
        account.syncFromHoldings(all.filter { $0.accountId == account.id })
    }
}