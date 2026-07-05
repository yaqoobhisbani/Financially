import SwiftUI
import SwiftData

struct PayContributionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let committee: Committee

    @State private var selectedAccountId: UUID?
    @State private var selectedAccountName: String?
    @State private var isOutside = false
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
                        Text("Month")
                        Spacer()
                        Text("\(committee.monthsCompleted + 1) of \(committee.totalMembers)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(committee.monthlyAmount.formattedCurrency())
                    }
                }

                Section("Source Account") {
                    AccountPickerButton(
                        label: "Pay From",
                        accountName: selectedAccountName,
                        placeholder: isOutside ? "Outside — No Account" : "Select account",
                        isOutside: isOutside,
                        action: { showAccountPicker = true }
                    )
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Pay Contribution")
            .formToolbar(label: "Pay", isDisabled: (selectedAccountId == nil && !isOutside)) { pay() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(
                    accounts: bankCashAccounts,
                    title: "Select Account",
                    filterType: nil,
                    onSelect: { account in
                        if let account {
                            selectedAccountId = account.id
                            selectedAccountName = account.name
                            isOutside = false
                        } else {
                            selectedAccountId = nil
                            selectedAccountName = nil
                            isOutside = true
                        }
                        showAccountPicker = false
                    },
                    showNoneOption: true
                )
            }
        }
    }

    private func pay() {
        guard selectedAccountId != nil || isOutside else { return }
        do {
            try vm.payContribution(committee: committee, sourceAccountId: isOutside ? nil : selectedAccountId, notes: notes.isEmpty ? nil : notes)
            dismiss()
        } catch {
            errorMessage = (error as? ValidationError)?.localizedDescription ?? error.localizedDescription
        }
    }
}