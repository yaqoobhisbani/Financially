import SwiftUI
import SwiftData

struct RecordRepaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let debtor: Debtor

    @State private var destinationAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var isFullRepayment = false
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
                    Toggle("Full Repayment", isOn: $isFullRepayment)
                        .onChange(of: isFullRepayment) { _, newValue in
                            if newValue {
                                amount = "\(debtor.outstandingBalance)"
                            } else if amount == "\(debtor.outstandingBalance)" {
                                amount = ""
                            }
                        }

                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    .disabled(isFullRepayment)

                    if let amountValue = Decimal(string: amount), amountValue > 0 {
                        if amountValue > debtor.outstandingBalance {
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
                            Text("Outstanding Balance")
                            Spacer()
                            Text(newOutstanding.formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Repayment from \(debtor.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") { save() }
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

    private var newOutstanding: Decimal {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return debtor.outstandingBalance }
        return max(0, debtor.outstandingBalance - amountValue)
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
        guard amountValue <= debtor.outstandingBalance else {
            errorMessage = "Repayment exceeds outstanding balance"
            return
        }

        debtor.totalRepaid += amountValue
        debtor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .loanRepayment,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: debtor.id,
            destinationAccountId: dest.id,
            relatedEntityId: debtor.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            debtor.totalRepaid -= amountValue
            errorMessage = error.localizedDescription
        } catch {
            debtor.totalRepaid -= amountValue
            errorMessage = error.localizedDescription
        }
    }
}