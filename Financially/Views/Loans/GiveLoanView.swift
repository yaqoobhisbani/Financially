import SwiftUI
import SwiftData

struct GiveLoanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let debtor: Debtor

    @Query private var accounts: [Account]
    @State private var vm: LoanTransactionViewModel?
    @State private var sourceAccount: Account?
    @State private var isOutside = false
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
                        placeholder: isOutside ? "Outside — No Account" : "Select Bank or Cash account",
                        isOutside: isOutside,
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
            .formToolbar(label: "Give Loan", isDisabled: (sourceAccount == nil && !isOutside) || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Source", filterType: nil, showNoneOption: true) { account in
                    if let account {
                        sourceAccount = account
                        isOutside = false
                    } else {
                        sourceAccount = nil
                        isOutside = true
                    }
                }
            }
        }
    }

    private func save() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { errorMessage = "Please enter a valid amount"; return }

        let vm = vm ?? LoanTransactionViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.giveLoan(to: debtor, amount: amountValue, date: date, description: description.isEmpty ? nil : description, sourceAccountId: isOutside ? nil : sourceAccount?.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}