import SwiftUI
import SwiftData

struct ReceiveMoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let creditor: Creditor

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

                Section("Amount") {
                    AmountField(amount: $amount)
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Description (optional)", text: $description)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Receive Money")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: destinationAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Destination", filterType: nil) { account in
                    destinationAccount = account
                }
            }
        }
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

        creditor.totalReceived += amountValue
        creditor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .liabilityReceived,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: dest.id,
            destinationAccountId: dest.id,
            relatedEntityId: creditor.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            creditor.totalReceived -= amountValue
            errorMessage = error.localizedDescription
        } catch {
            creditor.totalReceived -= amountValue
            errorMessage = error.localizedDescription
        }
    }
}