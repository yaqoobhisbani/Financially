import SwiftUI
import SwiftData

struct RedeemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @Query private var accounts: [Account]
    @Query private var allMFHoldings: [MutualFundHolding]
    @Query private var schemeList: [MutualFundScheme]

    @State private var selectedHolding: MutualFundHolding?
    @State private var selectedBank: Account?
    @State private var unitsValue = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showHoldingPicker = false
    @State private var showBankPicker = false
    @State private var errorMessage: String?

    private var bankAccounts: [Account] {
        Account.bankAndCash(from: accounts)
    }

    private var accountHoldings: [MutualFundHolding] {
        allMFHoldings.filter { $0.accountId == account.id && $0.totalUnits > 0 }
    }

    private var currentNavPrice: Decimal {
        guard let holding = selectedHolding else { return 0 }
        return holding.currentNavPrice ?? schemeList.first(where: { $0.fundCode == holding.fundCode })?.navPrice ?? 0
    }

    private var calculatedAmount: Decimal {
        (Decimal(string: unitsValue) ?? 0) * currentNavPrice
    }

    private var isFormValid: Bool {
        selectedHolding != nil && selectedBank != nil && !unitsValue.isEmpty && calculatedAmount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scheme") {
                    Button(action: { showHoldingPicker = true }) {
                        HStack {
                            Text("Fund")
                            Spacer()
                            if let holding = selectedHolding {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(holding.schemeName)
                                        .foregroundStyle(.primary)
                                    Text("Available: \(holding.totalUnits.formattedNumber()) units")
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

                Section("Redeem Details") {
                    HStack {
                        Text("Units")
                        Spacer()
                        TextField("0", text: $unitsValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if let holding = selectedHolding, let units = Decimal(string: unitsValue), units > holding.totalUnits {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                            Text("Exceeds available units (\(holding.totalUnits.formattedNumber()))")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if currentNavPrice > 0, let units = Decimal(string: unitsValue), units > 0 {
                        HStack {
                            Text("Redeem Amount")
                            Spacer()
                            Text(calculatedAmount.formattedCurrency())
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("NAV Price")
                            Spacer()
                            Text(currentNavPrice.formattedNAVPrice())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Bank Account") {
                    Button(action: { showBankPicker = true }) {
                        HStack {
                            Text("To")
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

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Redeem")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Redeem", isDisabled: !isFormValid) { redeem() }
            .sheet(isPresented: $showHoldingPicker) {
                holdingPicker
            }
            .sheet(isPresented: $showBankPicker) {
                AccountPickerView(accounts: bankAccounts, title: "Select Bank", filterType: nil) { account in
                    selectedBank = account
                }
            }
        }
    }

    private var holdingPicker: some View {
        NavigationStack {
            List(accountHoldings) { holding in
                Button(action: {
                    selectedHolding = holding
                    showHoldingPicker = false
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.schemeName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(holding.totalUnits.formattedNumber()) units")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(holding.currentValue.formattedCurrency())
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
                    Button("Cancel") { showHoldingPicker = false }
                }
            }
        }
    }

    private func redeem() {
        guard let holding = selectedHolding else { return }
        guard let bank = selectedBank else { return }
        guard let units = Decimal(string: unitsValue), units > 0 else {
            errorMessage = "Please enter valid units"
            return
        }
        guard units <= holding.totalUnits else {
            errorMessage = "Cannot redeem more than \(holding.totalUnits.formattedNumber()) units"
            return
        }

        let vm = MutualFundTradeViewModel(modelContext: modelContext, account: account, schemeList: schemeList, holdings: allMFHoldings)
        vm.redeem(
            holding: holding,
            units: units,
            navPrice: currentNavPrice,
            fees: 0,
            bankAccount: bank,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        try? modelContext.save()
        dismiss()
    }
}
