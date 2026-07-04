import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sourceAccount: Account?
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
                    Button(action: { showSourcePicker = true }) {
                        HStack {
                            Text("From")
                            Spacer()
                            if let account = sourceAccount {
                                Text(account.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select source")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(action: { showDestPicker = true }) {
                        HStack {
                            Text("To")
                            Spacer()
                            if let account = destinationAccount {
                                Text(account.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select destination")
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
                            .keyboardType(.decimalPad)
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
            }
            .navigationTitle("Transfer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") { saveTransfer() }
                        .disabled(sourceAccount == nil || destinationAccount == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showSourcePicker) {
                AccountPickerView(title: "Select Source", filterType: nil) { account in
                    guard account.accountType == .bank || account.accountType == .cash else {
                        errorMessage = "Can only transfer from Bank or Cash accounts."
                        return
                    }
                    sourceAccount = account
                }
            }
            .sheet(isPresented: $showDestPicker) {
                AccountPickerView(title: "Select Destination", filterType: nil) { account in
                    guard account.accountType == .bank || account.accountType == .cash else {
                        errorMessage = "Can only transfer to Bank or Cash accounts. Use Add Cash in PSX view instead."
                        return
                    }
                    destinationAccount = account
                }
            }
        }
    }

    private func saveTransfer() {
        guard let source = sourceAccount, let dest = destinationAccount else {
            errorMessage = "Please select both accounts"
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
            sourceAccountId: source.id,
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