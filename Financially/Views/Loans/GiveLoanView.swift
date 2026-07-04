import SwiftUI
import SwiftData

struct GiveLoanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let debtor: Debtor

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
                            Text("\(debtor.name)'s Outstanding")
                            Spacer()
                            Text((debtor.outstandingBalance + (Decimal(string: amount) ?? 0)).formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Give Loan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Give Loan") { save() }
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

    private func save() {
        guard let source = sourceAccount else {
            errorMessage = "Please select a source account"
            return
        }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        debtor.totalLent += amountValue
        debtor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .loanGiven,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: source.id,
            relatedEntityId: debtor.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            debtor.totalLent -= amountValue
            errorMessage = error.localizedDescription
        } catch {
            debtor.totalLent -= amountValue
            errorMessage = error.localizedDescription
        }
    }
}