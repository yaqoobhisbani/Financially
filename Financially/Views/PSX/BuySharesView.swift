import SwiftUI
import SwiftData

struct BuySharesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @Query(sort: \StockInfo.ticker) private var stockList: [StockInfo]
    @Query private var allHoldings: [StockHolding]

    @State private var vm: StockTradeViewModel?
    @State private var selectedStock: StockInfo?
    @State private var shares = ""
    @State private var pricePerShare = ""
    @State private var brokerageFee = ""
    @State private var tax = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showStockPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
                    Button(action: { showStockPicker = true }) {
                        HStack {
                            VStack(alignment: .leading) {
                                if let stock = selectedStock {
                                    Text(stock.companyName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(stock.ticker)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select a stock")
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
                        Text("Shares")
                        Spacer()
                        TextField("0", text: $shares)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Price per Share")
                        Spacer()
                        TextField("0", text: $pricePerShare)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let total = totalAmount {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(total.formattedCurrency(currency: account.currency))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                FeeSection(
                    brokerageFee: $brokerageFee,
                    tax: $tax,
                    netLabel: "Net Cost",
                    netValue: netAmount?.formattedCurrency(currency: account.currency)
                )

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes)
                }

                if account.currentBalance < (netAmount ?? 0) {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Insufficient cash. Available: \(account.currentBalance.formattedCurrency(currency: account.currency))")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Buy Shares")
            .formToolbar(label: "Buy", isDisabled: selectedStock == nil || shares.isEmpty || pricePerShare.isEmpty) { save() }
            .sheet(isPresented: $showStockPicker) { stockPicker }
        }
    }

    private var stockPicker: some View {
        NavigationStack {
            List(stockList) { stock in
                Button {
                    selectedStock = stock
                    pricePerShare = stock.currentRate > 0 ? "\(stock.currentRate)" : ""
                    showStockPicker = false
                } label: {
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
                                .font(.subheadline.bold())
                            Text("per share")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Select Stock")
        }
    }

    private var sharesValue: Int? { Int(shares) }
    private var priceValue: Decimal? { Decimal(string: pricePerShare) }
    private var totalAmount: Decimal? {
        guard let s = sharesValue, let p = priceValue else { return nil }
        return Decimal(s) * p
    }
    private var brokerageValue: Decimal { Decimal(string: brokerageFee) ?? 0 }
    private var taxValue: Decimal { Decimal(string: tax) ?? 0 }
    private var netAmount: Decimal? {
        guard let total = totalAmount else { return nil }
        return total + brokerageValue + taxValue
    }

    private func save() {
        guard let stock = selectedStock else { errorMessage = "Please select a stock"; return }
        guard let shares = sharesValue, shares > 0 else {
            errorMessage = "Please enter a valid number of shares"; return
        }
        guard let price = priceValue, price > 0 else {
            errorMessage = "Please enter a valid price per share"; return
        }
        guard let net = netAmount, net > 0 else {
            errorMessage = "Please enter valid amounts"; return
        }
        guard net <= account.currentBalance else {
            errorMessage = "Insufficient cash available"; return
        }

        let vm = vm ?? StockTradeViewModel(modelContext: modelContext, account: account, stockList: stockList, holdings: allHoldings)
        self.vm = vm

        vm.buy(
            ticker: stock.ticker,
            companyName: stock.companyName,
            shares: shares,
            pricePerShare: price,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netAmount: net,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        dismiss()
    }
}