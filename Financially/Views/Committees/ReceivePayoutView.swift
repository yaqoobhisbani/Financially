import SwiftUI
import SwiftData

struct ReceivePayoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let committee: Committee

    @State private var selectedAccountId: UUID?
    @State private var selectedAccountName: String?
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
                        Text("Payout Amount")
                        Spacer()
                        Text(committee.totalPayout.formattedCurrency())
                            .font(.headline)
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
            .navigationTitle("Receive Payout")
            .formToolbar(label: "Receive", isDisabled: selectedAccountId == nil) { receive() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(
                    accounts: bankCashAccounts,
                    title: "Select Account",
                    filterType: nil,
                    onSelect: { account in
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
        do {
            try vm.receivePayout(committee: committee, destinationAccountId: accountId, notes: notes.isEmpty ? nil : notes)
            dismiss()
        } catch {
            errorMessage = (error as? ValidationError)?.localizedDescription ?? error.localizedDescription
        }
    }
}