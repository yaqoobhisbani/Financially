import SwiftUI
import SwiftData

struct CreateAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let accountType: AccountType

    @State private var vm: AccountViewModel?

    @State private var name = ""
    @State private var selectedBank: String?
    @State private var cashSubType: CashSubType = .wallet
    @State private var accountNumber = ""
    @State private var initialBalanceString = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    private let popularBanks = [
        "Meezan Bank",
        "HBL",
        "UBL",
        "National Bank",
        "Allied Bank",
        "MCB",
        "Bank Alfalah",
        "SadaPay",
        "NayaPay",
        "JazzCash",
        "EasyPaisa",
        "Other",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Account Name", text: $name)

                    if accountType == .bank {
                        Picker("Bank", selection: $selectedBank) {
                            ForEach(popularBanks, id: \.self) { bank in
                                Text(bank).tag(bank as String?)
                            }
                        }
                        TextField("Account Number (last 4 digits)", text: $accountNumber)
                    } else {
                        Picker("Sub Type", selection: $cashSubType) {
                            ForEach(CashSubType.allCases, id: \.self) { sub in
                                Text(sub.rawValue.capitalized).tag(sub)
                            }
                        }
                    }
                }

                Section("Balance") {
                    HStack {
                        Text("Initial Balance")
                        Spacer()
                        TextField("0", text: $initialBalanceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New \(accountType == .bank ? "Bank" : "Cash") Account")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: name.isEmpty) { saveAccount() }
        }
    }

    private func saveAccount() {
        guard !name.isEmpty else {
            errorMessage = "Account name is required"
            return
        }

        let initialBalance = Decimal(string: initialBalanceString) ?? 0

        let vm = vm ?? AccountViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.createAccount(
                name: name,
                accountType: accountType,
                bankSubType: nil,
                cashSubType: accountType == .cash ? cashSubType : nil,
                bankName: accountType == .bank ? selectedBank : nil,
                accountNumber: accountNumber.isEmpty ? nil : accountNumber,
                initialBalance: initialBalance,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save account"
        }
    }
}