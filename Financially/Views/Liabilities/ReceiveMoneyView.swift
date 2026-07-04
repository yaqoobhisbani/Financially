import SwiftUI
import SwiftData

struct ReceiveMoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let creditor: Creditor

    @Query private var accounts: [Account]
    @State private var vm: LoanTransactionViewModel?
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
                    AccountPickerButton(
                        label: "To",
                        accountName: destinationAccount?.name,
                        placeholder: "Select Bank or Cash account",
                        action: { showAccountPicker = true }
                    )
                }

                Section("Amount") { AmountField(amount: $amount) }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }
                Section("Notes") { TextField("Description (optional)", text: $description) }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Receive Money")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: destinationAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Destination", filterType: nil) { account in
                    destinationAccount = account
                }
            }
        }
    }

    private func save() {
        guard let dest = destinationAccount else { errorMessage = "Please select a destination account"; return }

        let vm = vm ?? LoanTransactionViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.receiveMoney(from: creditor, amount: amount, date: date, description: description.isEmpty ? nil : description, destinationAccountId: dest.id)
            dismiss()
        } catch let error as LoanTransactionViewModel.LoanError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}