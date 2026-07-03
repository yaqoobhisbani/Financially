import SwiftUI
import SwiftData

struct CreateAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var accountType: AccountType = .bank
    @State private var selectedBank: String?
    @State private var cashSubType: CashSubType = .wallet
    @State private var accountNumber = ""
    @State private var brokerName = ""
    @State private var fundHouse = ""
    @State private var initialBalanceString = ""
    @State private var investedAmountString = ""
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
                Section("Account Type") {
                    Picker("Type", selection: $accountType) {
                        Text("Bank").tag(AccountType.bank)
                        Text("Cash").tag(AccountType.cash)
                        Text("PSX Stock").tag(AccountType.psx)
                        Text("Mutual Fund").tag(AccountType.mutualFund)
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

                    case .mutualFund:
                        TextField("Fund House", text: $fundHouse)
                    }
                }

                Section("Balance") {
                    if accountType == .psx || accountType == .mutualFund {
                        HStack {
                            Text("Invested Amount")
                            Spacer()
                            TextField("0", text: $investedAmountString)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("Initial Balance")
                            Spacer()
                            TextField("0", text: $initialBalanceString)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAccount() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveAccount() {
        guard !name.isEmpty else {
            errorMessage = "Account name is required"
            return
        }

        let initialBalance = Decimal(string: initialBalanceString) ?? 0
        let investedAmount = Decimal(string: investedAmountString) ?? 0

        let account = Account(
            name: name,
            accountType: accountType,
            cashSubType: accountType == .cash ? cashSubType : nil,
            bankName: accountType == .bank ? selectedBank : nil,
            accountNumber: accountNumber.isEmpty ? nil : accountNumber,
            brokerName: brokerName.isEmpty ? nil : brokerName,
            fundHouse: fundHouse.isEmpty ? nil : fundHouse,
            initialBalance: accountType == .psx ? investedAmount : initialBalance,
            investedAmount: accountType == .psx ? 0 : investedAmount,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(account)
        dismiss()
    }
}

#Preview {
    CreateAccountView()
}