import SwiftUI
import SwiftData

struct ReceivePayoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let committee: Committee

    @State private var selectedAccountId: UUID?
    @State private var selectedAccountName: String?
    @State private var amount = ""
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showAccountPicker = false

    private var bankCashAccounts: [Account] {
        let fetch = FetchDescriptor<Account>(predicate: #Predicate { $0.isActive })
        return (try? modelContext.fetch(fetch))?.filter { $0.accountType == .bank || $0.accountType == .cash } ?? []
    }

    private var vm: CommitteeViewModel {
        CommitteeViewModel(modelContext: modelContext)
    }

    private var existingPayouts: [CommitteePayout] {
        let committeeId = committee.id
        let predicate = #Predicate<CommitteePayout> { $0.committeeId == committeeId }
        return (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private var totalReceived: Decimal {
        existingPayouts.reduce(0) { $0 + $1.amount }
    }

    private var remainingPayout: Decimal {
        max(0, committee.myTotalPayout - totalReceived)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Committee") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(committee.name)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Payout")
                        Spacer()
                        Text(committee.myTotalPayout.formattedCurrency())
                            .font(.headline)
                    }
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(remainingPayout.formattedCurrency())
                            .foregroundStyle(remainingPayout > 0 ? .primary : .secondary)
                    }
                }

                Section("Amount") {
                    AmountField(amount: $amount)
                    if remainingPayout > 0 {
                        Button("Full Amount (\(remainingPayout.formattedCurrency()))") {
                            amount = "\(remainingPayout)"
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }

                Section("Destination Account") {
                    AccountPickerButton(
                        label: "Deposit To",
                        accountName: selectedAccountName,
                        action: { showAccountPicker = true }
                    )
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Receive Payout").font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Receive") { receive() }
                        .disabled(selectedAccountId == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(
                    accounts: bankCashAccounts,
                    title: "Select Account",
                    filterType: nil,
                    onSelect: { account in
                        guard let account else { return }
                        selectedAccountId = account.id
                        selectedAccountName = account.name
                        showAccountPicker = false
                    }
                )
            }
        }
    }

    private func receive() {
        guard let accountId = selectedAccountId else { return }
        guard let payoutAmount = Decimal(string: amount), payoutAmount > 0 else {
            errorMessage = "Invalid amount"
            return
        }
        guard payoutAmount <= remainingPayout else {
            errorMessage = "Amount exceeds remaining payout of \(remainingPayout.formattedCurrency())"
            return
        }
        do {
            try vm.receivePayout(committee: committee, destinationAccountId: accountId, amount: payoutAmount, notes: notes.isEmpty ? nil : notes)
            dismiss()
        } catch {
            errorMessage = (error as? ValidationError)?.localizedDescription ?? error.localizedDescription
        }
    }
}
