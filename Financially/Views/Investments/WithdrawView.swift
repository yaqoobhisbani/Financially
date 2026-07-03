import SwiftUI
import SwiftData

struct WithdrawView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var destinationAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showAccountPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination Account") {
                    Button(action: { showAccountPicker = true }) {
                        HStack {
                            Text("To")
                            Spacer()
                            if let account = destinationAccount {
                                Text(account.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select Bank or Cash account")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }

                    if let amountValue = Decimal(string: amount), amountValue > 0 {
                        HStack {
                            Text("Available for withdrawal")
                            Spacer()
                            Text(account.currentValue.formattedCurrency(currency: account.currency))
                                .foregroundStyle(.secondary)
                        }

                        if amountValue > account.currentValue {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text("Amount exceeds current value")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Description (optional)", text: $description)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After this transaction:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("Invested Amount")
                            Spacer()
                            Text(newInvestedAmount.formattedCurrency(currency: account.currency))
                        }
                        HStack {
                            Text("Current Value")
                            Spacer()
                            Text(newCurrentValue.formattedCurrency(currency: account.currency))
                        }
                    }
                }
            }
            .navigationTitle("Withdraw / Sell")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Withdraw") { save() }
                        .disabled(destinationAccount == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Destination", filterType: nil) { account in
                    destinationAccount = account
                }
            }
        }
    }

    private var newInvestedAmount: Decimal {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return account.investedAmount }
        return max(0, account.investedAmount - amountValue)
    }

    private var newCurrentValue: Decimal {
        newInvestedAmount + account.totalProfitLoss
    }

    private func save() {
        guard let dest = destinationAccount else {
            errorMessage = "Please select a destination account"
            return
        }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .investmentWithdrawal,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: account.id,
            destinationAccountId: dest.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}