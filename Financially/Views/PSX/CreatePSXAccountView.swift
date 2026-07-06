import SwiftUI
import SwiftData

struct CreatePSXAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: AccountViewModel?

    @State private var name = ""
    @State private var brokerName = ""
    @State private var fundHouse = ""
    @State private var investedAmountString = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Account Name", text: $name)
                    TextField("Broker Name", text: $brokerName)
                }

                Section("Balance") {
                    HStack {
                        Text("Invested Amount")
                        Spacer()
                        TextField("0", text: $investedAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New PSX Account")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: name.isEmpty) { saveAccount() }
        }
    }

    private func saveAccount() {
        guard !name.isEmpty else {
            errorMessage = "Account name is required"
            return
        }

        let investedAmount = Decimal(string: investedAmountString) ?? 0

        let vm = vm ?? AccountViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.createAccount(
                name: name,
                accountType: .psx,
                brokerName: brokerName.isEmpty ? nil : brokerName,
                fundHouse: fundHouse.isEmpty ? nil : fundHouse,
                initialBalance: investedAmount,
                investedAmount: 0,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save account"
        }
    }
}