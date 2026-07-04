import SwiftUI
import SwiftData

struct PayBackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let creditor: Creditor

    @State private var sourceAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var isFullPayback = false
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
                    Toggle("Full Payback", isOn: $isFullPayback)
                        .onChange(of: isFullPayback) { _, newValue in
                            if newValue {
                                amount = "\(creditor.outstandingBalance)"
                            } else if amount == "\(creditor.outstandingBalance)" {
                                amount = ""
                            }
                        }

                    AmountField(amount: $amount)
                    .disabled(isFullPayback)

                    if let amountValue = Decimal(string: amount), amountValue > 0 {
                        if amountValue > creditor.outstandingBalance {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text("Amount exceeds outstanding balance")
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
                            Text("Outstanding Liability")
                            Spacer()
                            Text(newOutstanding.formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Pay Back")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay") { save() }
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

    private var newOutstanding: Decimal {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return creditor.outstandingBalance }
        return max(0, creditor.outstandingBalance - amountValue)
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
        guard amountValue <= creditor.outstandingBalance else {
            errorMessage = "Payback exceeds outstanding balance"
            return
        }

        creditor.totalReturned += amountValue
        creditor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .liabilityPayback,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: source.id,
            relatedEntityId: creditor.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            creditor.totalReturned -= amountValue
            errorMessage = error.localizedDescription
        } catch {
            creditor.totalReturned -= amountValue
            errorMessage = error.localizedDescription
        }
    }
}