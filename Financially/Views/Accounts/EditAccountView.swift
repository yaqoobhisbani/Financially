import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var account: Account

    @State private var name: String
    @State private var accountType: AccountType
    @State private var selectedBank: String?
    @State private var cashSubType: CashSubType
    @State private var accountNumber: String
    @State private var brokerName: String
    @State private var fundHouse: String
    @State private var notes: String
    @State private var errorMessage: String?

    private let popularBanks = [
        "Meezan Bank", "HBL", "UBL", "National Bank", "Allied Bank",
        "MCB", "Bank Alfalah", "SadaPay", "NayaPay", "JazzCash", "EasyPaisa", "Other",
    ]

    init(account: Account) {
        self.account = account
        _name = State(initialValue: account.name)
        _accountType = State(initialValue: account.accountType)
        _selectedBank = State(initialValue: account.bankName)
        _cashSubType = State(initialValue: account.cashSubType ?? .wallet)
        _accountNumber = State(initialValue: account.accountNumber ?? "")
        _brokerName = State(initialValue: account.brokerName ?? "")
        _fundHouse = State(initialValue: account.fundHouse ?? "")
        _notes = State(initialValue: account.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Type") {
                    Picker("Type", selection: $accountType) {
                        Text("Bank").tag(AccountType.bank)
                        Text("Cash").tag(AccountType.cash)
                        Text("PSX Stock").tag(AccountType.psx)
                    }
                }

                Section("Details") {
                    TextField("Account Name", text: $name)

                    switch accountType {
                    case .bank:
                        Picker("Bank", selection: $selectedBank) {
                            ForEach(popularBanks, id: \.self) { bank in
                                Text(bank).tag(bank as String?)
                            }
                        }
                        TextField("Account Number (last 4 digits)", text: $accountNumber)

                    case .cash:
                        Picker("Sub Type", selection: $cashSubType) {
                            ForEach(CashSubType.allCases, id: \.self) { sub in
                                Text(sub.rawValue.capitalized).tag(sub)
                            }
                        }

                    case .psx:
                        TextField("Broker Name", text: $brokerName)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: name.isEmpty) { save() }
        }
    }

    private func save() {
        guard !name.isEmpty else {
            errorMessage = "Account name is required"
            return
        }

        account.name = name
        account.accountType = accountType
        account.cashSubType = accountType == .cash ? cashSubType : nil
        account.bankName = accountType == .bank ? selectedBank : nil
        account.accountNumber = accountNumber.isEmpty ? nil : accountNumber
        account.brokerName = brokerName.isEmpty ? nil : brokerName
        account.fundHouse = fundHouse.isEmpty ? nil : fundHouse
        account.notes = notes.isEmpty ? nil : notes
        account.updatedAt = Date()

        dismiss()
    }
}