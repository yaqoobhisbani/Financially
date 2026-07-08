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
    @State private var selectedScheme: MutualFundScheme?
    @State private var unitsOrAmount: UnitsOrAmount = .units
    @State private var unitsValue = ""
    @State private var amountValue = ""
    @State private var feesValue = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showBankPicker = false
    @State private var showSchemePicker = false
    @State private var errorMessage: String?

    enum UnitsOrAmount: String, CaseIterable {
        case units = "Units"
        case amount = "Amount"
    }

    private var bankAccounts: [Account] {
        Account.bankAndCash(from: accounts)
    }

    private var navPrice: Decimal {
        selectedScheme?.navPrice ?? 0
    }

    private var calculatedUnits: Decimal {
        if unitsOrAmount == .units {
            return Decimal(string: unitsValue) ?? 0
        }
        guard navPrice > 0 else { return 0 }
        return (Decimal(string: amountValue) ?? 0) / navPrice
    }

    private var calculatedAmount: Decimal {
        if unitsOrAmount == .amount {
            return Decimal(string: amountValue) ?? 0
        }
        return (Decimal(string: unitsValue) ?? 0) * navPrice
    }

    private var isFormValid: Bool {
        selectedBank != nil && selectedScheme != nil && ((!unitsValue.isEmpty && unitsOrAmount == .units) || (!amountValue.isEmpty && unitsOrAmount == .amount)) && calculatedAmount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bank Account") {
                    Button(action: { showBankPicker = true }) {
                        HStack {
                            Text("From")
                            Spacer()
                            if let bank = selectedBank {
                                Text(bank.name).foregroundStyle(.primary)
                            } else {
                                Text("Select account").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
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
                                    Text("NAV: \(scheme.navPrice.formattedCurrency())")
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
                    Picker("By", selection: $unitsOrAmount) {
                        ForEach(UnitsOrAmount.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if unitsOrAmount == .units {
                        HStack {
                            Text("Units")
                            Spacer()
                            TextField("0", text: $unitsValue)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        if navPrice > 0, let units = Decimal(string: unitsValue), units > 0 {
                            HStack {
                                Text("Investment Amount")
                                Spacer()
                                Text((units * navPrice).formattedCurrency())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", text: $amountValue)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        if navPrice > 0, let amount = Decimal(string: amountValue), amount > 0 {
                            HStack {
                                Text("Units")
                                Spacer()
                                Text((amount / navPrice).formattedNumber())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("Fees")
                        Spacer()
                        TextField("0", text: $feesValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

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
                AccountPickerView(accounts: bankAccounts, title: "Select Bank", filterType: nil) { account in
                    selectedBank = account
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
                        Text(scheme.navPrice.formattedCurrency())
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
        guard let bank = selectedBank else { return }
        guard let scheme = selectedScheme else { return }
        let units = calculatedUnits
        let amount = calculatedAmount
        guard units > 0, amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        guard amount <= bank.currentBalance else {
            errorMessage = "Insufficient balance in \(bank.name)"
            return
        }

        let fees = Decimal(string: feesValue) ?? 0

        let vm = MutualFundTradeViewModel(modelContext: modelContext, account: account, schemeList: schemeList, holdings: allMFHoldings)
        vm.invest(
            bankAccount: bank,
            scheme: scheme,
            units: units,
            navPrice: navPrice,
            fees: fees,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        try? modelContext.save()
        dismiss()
    }
}
