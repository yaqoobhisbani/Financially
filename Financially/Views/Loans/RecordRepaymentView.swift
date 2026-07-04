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
                    AccountPickerButton(
                        label: "To",
                        accountName: destinationAccount?.name,
                        placeholder: "Select Bank or Cash account",
                        action: { showAccountPicker = true }
                    )
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

                    AmountField(amount: $amount)
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

                FormErrorSection(message: errorMessage)

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
            .navigationTitle("Record Repayment")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Record", isDisabled: destinationAccount == nil || amount.isEmpty) { save() }
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
            sourceAccountId: dest.id,
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