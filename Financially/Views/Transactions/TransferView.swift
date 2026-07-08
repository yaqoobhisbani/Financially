import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var accounts: [Account]
    @State private var sourceAccount: Account?
    @State private var isOutside = false
    @State private var destinationAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showSourcePicker = false
    @State private var showDestPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Accounts") {
                    AccountPickerButton(
                        label: "From",
                        accountName: sourceAccount?.name,
                        placeholder: isOutside ? "Outside — No Account" : "Select source",
                        isOutside: isOutside,
                        action: { showSourcePicker = true }
                    )

                    AccountPickerButton(
                        label: "To",
                        accountName: destinationAccount?.name,
                        placeholder: "Select destination",
                        action: { showDestPicker = true }
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
            .navigationTitle("Transfer")
            .formToolbar(label: "Transfer", isDisabled: (sourceAccount == nil && !isOutside) || destinationAccount == nil || amount.isEmpty) { saveTransfer() }
            .sheet(isPresented: $showSourcePicker) {
                AccountPickerView(accounts: Account.bankAndCash(from: accounts), title: "Select Source", filterType: nil, showNoneOption: true) { account in
                    if let account {
                        sourceAccount = account
                        isOutside = false
                    } else {
                        sourceAccount = nil
                        isOutside = true
                    }
                }
            }
            .sheet(isPresented: $showDestPicker) {
                AccountPickerView(accounts: Account.bankAndCash(from: accounts), title: "Select Destination", filterType: nil) { account in
                    guard let account else { return }
                    destinationAccount = account
                }
            }
        }
    }

    private func saveTransfer() {
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
            type: .transfer,
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            sourceAccountId: isOutside ? nil : sourceAccount?.id,
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