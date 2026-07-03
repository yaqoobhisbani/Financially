import SwiftUI
import SwiftData

struct AddCapitalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var sourceAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showAccountPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Account") {
                    Button(action: { showAccountPicker = true }) {
                        HStack {
                            Text("From")
                            Spacer()
                            if let account = sourceAccount {
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
            .navigationTitle("Add Capital")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(sourceAccount == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Source", filterType: nil) { account in
                    sourceAccount = account
                }
            }
        }
    }

    private var newInvestedAmount: Decimal {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return account.investedAmount }
        return account.investedAmount + amountValue
    }

    private var newCurrentValue: Decimal {
        newInvestedAmount + account.totalProfitLoss
    }

    private func save() {
        guard let source = sourceAccount else {
            errorMessage = "Please select a source account"
            return
        }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .investmentAddCapital,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: source.id,
            destinationAccountId: account.id
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