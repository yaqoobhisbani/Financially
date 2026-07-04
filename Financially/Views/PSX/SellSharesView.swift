import SwiftUI
import SwiftData

struct SellSharesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var vm: StockTradeViewModel?
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
    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]

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

                FeeSection(
                    brokerageFee: $brokerageFee,
                    tax: $tax,
                    netLabel: "Net Proceeds",
                    netValue: netProceeds?.formattedCurrency(currency: account.currency)
                )

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Sell Shares")
            .formToolbar(label: "Sell", isDisabled: selectedHolding == nil || shares.isEmpty || pricePerShare.isEmpty) { save() }
            .sheet(isPresented: $showHoldingPicker) { holdingPicker }
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
            .buttonStyle(.plain)
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
            errorMessage = "Please select a holding"; return
        }
        guard let shares = sharesValue, shares > 0 else {
            errorMessage = "Please enter a valid number of shares"; return
        }
        guard shares <= holding.totalShares else {
            errorMessage = "Cannot sell more shares than you hold"; return
        }
        guard let price = priceValue, price > 0 else {
            errorMessage = "Please enter a valid price per share"; return
        }
        guard let proceeds = netProceeds, proceeds > 0 else {
            errorMessage = "Net proceeds must be positive"; return
        }

        let vm = vm ?? StockTradeViewModel(modelContext: modelContext, account: account, stockList: stockList, holdings: holdings)
        self.vm = vm

        vm.sell(
            holding: holding,
            shares: shares,
            pricePerShare: price,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netProceeds: proceeds,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        dismiss()
    }
}