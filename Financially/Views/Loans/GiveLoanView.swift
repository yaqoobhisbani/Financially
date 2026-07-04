import SwiftUI
import SwiftData

struct GiveLoanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let debtor: Debtor

    @Query private var accounts: [Account]
    @State private var vm: LoanTransactionViewModel?
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
                    AccountPickerButton(
                        label: "From",
                        accountName: sourceAccount?.name,
                        placeholder: "Select Bank or Cash account",
                        action: { showAccountPicker = true }
                    )
                }

                Section("Amount") { AmountField(amount: $amount) }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                Section("Notes") { TextField("Description (optional)", text: $description) }

                FormErrorSection(message: errorMessage)

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
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Give Loan", isDisabled: sourceAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Source", filterType: nil) { account in
                    sourceAccount = account
                }
            }
        }
    }

    private func save() {
        guard let source = sourceAccount else { errorMessage = "Please select a source account"; return }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { errorMessage = "Please enter a valid amount"; return }

        let vm = vm ?? LoanTransactionViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.giveLoan(to: debtor, amount: amountValue, date: date, description: description.isEmpty ? nil : description, sourceAccountId: source.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}