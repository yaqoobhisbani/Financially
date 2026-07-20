import SwiftUI
import SwiftData

struct InvestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @Query private var accounts: [Account]
    @Query private var schemeList: [MutualFundScheme]
    @Query private var allMFHoldings: [MutualFundHolding]

    @State private var selectedBank: Account?
    @State private var isOutside = false
    @State private var selectedScheme: MutualFundScheme?
    @State private var unitsValue = ""
    @State private var navPriceValue = ""
    @State private var feesValue = ""
    @State private var taxValue = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showBankPicker = false
    @State private var showSchemePicker = false
    @State private var errorMessage: String?

    private var bankAccounts: [Account] {
        Account.bankAndCash(from: accounts)
    }

    private var enteredUnits: Decimal {
        Decimal(string: unitsValue) ?? 0
    }

    private var enteredNavPrice: Decimal {
        Decimal(string: navPriceValue) ?? 0
    }

    private var calculatedAmount: Decimal {
        enteredUnits * enteredNavPrice
    }

    private var enteredFees: Decimal {
        Decimal(string: feesValue) ?? 0
    }

    private var enteredTax: Decimal {
        Decimal(string: taxValue) ?? 0
    }

    private var netCost: Decimal {
        calculatedAmount + enteredFees + enteredTax
    }

    private var isFormValid: Bool {
        (selectedBank != nil || isOutside) && selectedScheme != nil && enteredUnits > 0 && enteredNavPrice > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bank Account") {
                    AccountPickerButton(
                        label: "From",
                        accountName: selectedBank?.name,
                        placeholder: isOutside ? "Outside — No Account" : "Select account",
                        isOutside: isOutside,
                        action: { showBankPicker = true }
                    )
                }

                Section("Scheme") {
                    Button(action: { showSchemePicker = true }) {
                        HStack {
                            Text("Fund")
                            Spacer()
                            if let scheme = selectedScheme {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(scheme.schemeName)
                                        .foregroundStyle(.primary)
                                    Text("NAV: \(scheme.navPrice.formattedNAVPrice())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Select scheme").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Investment Details") {
                    HStack {
                        Text("Units")
                        Spacer()
                        TextField("0", text: $unitsValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("NAV Price")
                        Spacer()
                        TextField(selectedScheme?.navPrice.formattedNAVPrice() ?? "0.0000", text: $navPriceValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(calculatedAmount.formattedCurrency())
                            .foregroundStyle(.secondary)
                    }
                }

                FeeSection(
                    brokerageFee: $feesValue,
                    tax: $taxValue,
                    feeLabel: "Fees",
                    netLabel: "Net Cost",
                    netValue: calculatedAmount > 0 ? netCost.formattedCurrency() : nil
                )

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Invest")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Invest", isDisabled: !isFormValid) { invest() }
            .sheet(isPresented: $showBankPicker) {
                AccountPickerView(accounts: bankAccounts, title: "Select Bank", filterType: nil, showNoneOption: true) { account in
                    if let account {
                        selectedBank = account
                        isOutside = false
                    } else {
                        selectedBank = nil
                        isOutside = true
                    }
                }
            }
            .sheet(isPresented: $showSchemePicker) {
                schemePicker
            }
        }
    }

    private var schemePicker: some View {
        NavigationStack {
            List(schemeList) { scheme in
                Button(action: {
                    selectedScheme = scheme
                    showSchemePicker = false
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scheme.schemeName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(scheme.fundCode)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(scheme.navPrice.formattedNAVPrice())
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Scheme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSchemePicker = false }
                }
            }
        }
    }

    private func invest() {
        guard let scheme = selectedScheme else { return }
        let units = enteredUnits
        let navPrice = enteredNavPrice
        let amount = calculatedAmount
        guard units > 0, navPrice > 0, amount > 0 else {
            errorMessage = "Please enter valid units and NAV price"
            return
        }
        let fees = enteredFees
        let tax = enteredTax
        let totalCost = amount + fees + tax

        if let bank = selectedBank, !isOutside {
            guard totalCost <= bank.currentBalance else {
                errorMessage = "Insufficient balance in \(bank.name)"
                return
            }
        }

        let vm = MutualFundTradeViewModel(modelContext: modelContext, account: account, schemeList: schemeList, holdings: allMFHoldings)
        vm.invest(
            bankAccount: isOutside ? nil : selectedBank,
            scheme: scheme,
            units: units,
            navPrice: navPrice,
            fees: fees,
            tax: tax,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        try? modelContext.save()
        dismiss()
    }
}
