import SwiftUI
import SwiftData

struct BuyCommodityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @Query private var allHoldings: [CommodityHolding]
    @Query private var accounts: [Account]

    @State private var vm: CommodityTradeViewModel?
    @State private var selectedCommodity: CommodityInfo?
    @State private var sourceAccount: Account?
    @State private var isOutside = false
    @State private var grams = ""
    @State private var pricePerGram = ""
    @State private var brokerageFee = ""
    @State private var tax = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showCommodityPicker = false
    @State private var showAccountPicker = false

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

                Section("From Account") {
                    AccountPickerButton(
                        label: "From",
                        accountName: sourceAccount?.name,
                        placeholder: isOutside ? "Outside — No Account" : "Select account",
                        isOutside: isOutside,
                        action: { showAccountPicker = true }
                    )
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

                FeeSection(
                    brokerageFee: $brokerageFee,
                    tax: $tax,
                    netLabel: "Net Cost",
                    netValue: netAmount?.formattedCurrency()
                )

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                Section("Notes") { TextField("Optional", text: $notes) }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Buy Commodity")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Buy", isDisabled: selectedCommodity == nil || grams.isEmpty || pricePerGram.isEmpty || (sourceAccount == nil && !isOutside)) { save() }
            .sheet(isPresented: $showCommodityPicker) { commodityPicker }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: Account.bankAndCash(from: accounts), title: "Select Account", filterType: nil, showNoneOption: true) { account in
                    if let account {
                        sourceAccount = account
                        isOutside = false
                    } else {
                        sourceAccount = nil
                        isOutside = true
                    }
                }
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
            .buttonStyle(.plain)
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
        guard let gramsVal = gramsValue, gramsVal > 0 else { errorMessage = "Please enter a valid number of grams"; return }
        guard let price = priceValue, price > 0 else { errorMessage = "Please enter a valid price per gram"; return }
        guard let net = netAmount, net > 0 else { errorMessage = "Please enter valid amounts"; return }

        let ledger = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .commodityBuy,
            amount: net,
            date: date,
            description: "Buy \(commodity.name) (\(gramsVal.formattedNumber())g)",
            sourceAccountId: isOutside ? nil : sourceAccount?.id
        )
        let transaction: Transaction
        do {
            transaction = try ledger.execute(request)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let vm = vm ?? CommodityTradeViewModel(modelContext: modelContext, commodityList: commodityList, holdings: allHoldings)
        self.vm = vm

        let symbol = commodity.name.localizedCaseInsensitiveContains("gold") ? "XAU" : "XAG"
        vm.buy(
            symbol: symbol,
            commodityName: commodity.name,
            grams: gramsVal,
            pricePerGram: price,
            brokerageFee: brokerageValue,
            tax: taxValue,
            netAmount: net,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            transactionId: transaction.id
        )

        try? modelContext.save()
        dismiss()
    }
}