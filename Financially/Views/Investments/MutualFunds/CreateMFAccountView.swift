import SwiftUI
import SwiftData

struct CreateMFAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: AccountViewModel?
    @State private var name = ""
    @State private var selectedFundHouse = ""
    @State private var showCustomFundHouse = false
    @State private var customFundHouse = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    private var fundHouse: String {
        selectedFundHouse == "Other" ? customFundHouse : selectedFundHouse
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Account Name", text: $name)
                    if showCustomFundHouse {
                        TextField("Fund House Name", text: $customFundHouse)
                    } else {
                        Picker("Fund House", selection: $selectedFundHouse) {
                            Text("Select").tag("")
                            ForEach(FundHouses.all, id: \.self) { house in
                                Text(house).tag(house)
                            }
                            Text("Other").tag("Other")
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New MF Account")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: name.isEmpty || fundHouse.isEmpty) { saveAccount() }
            .onChange(of: selectedFundHouse) { _, newValue in
                showCustomFundHouse = newValue == "Other"
            }
        }
    }

    private func saveAccount() {
        guard !name.isEmpty else {
            errorMessage = "Account name is required"
            return
        }
        guard !fundHouse.isEmpty else {
            errorMessage = "Fund house is required"
            return
        }

        let vm = vm ?? AccountViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.createAccount(
                name: name,
                accountType: .mutualFund,
                fundHouse: fundHouse,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save account"
        }
    }
}
