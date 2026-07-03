import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @Query private var ledgerEntries: [LedgerEntry]
    @State private var showStatement = false
    @State private var showEdit = false

    init(account: Account) {
        self.account = account
        let accountId = account.id
        _ledgerEntries = Query(filter: #Predicate<LedgerEntry> { $0.accountId == accountId }, sort: \.date, order: .reverse)
    }

    var body: some View {
        List {
            balanceSection
            accountInfoSection
            if account.accountType == .psx || account.accountType == .mutualFund {
                investmentSection
            }
            recentTransactionsSection
        }
        .navigationTitle(account.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("View Statement", systemImage: "doc.text") { showStatement = true }
                    Button("Edit Account", systemImage: "pencil") { showEdit = true }
                    Button(account.isActive ? "Deactivate" : "Activate", systemImage: account.isActive ? "eye.slash" : "eye") {
                        account.isActive.toggle()
                        account.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showStatement) {
            AccountStatementView(account: account)
        }
    }

    private var balanceSection: some View {
        Section {
            VStack(spacing: 8) {
                if account.accountType == .psx || account.accountType == .mutualFund {
                    HStack {
                        Text("Invested")
                        Spacer()
                        Text(account.investedAmount.formattedCurrency(currency: account.currency))
                    }
                    HStack {
                        Text("P/L")
                        Spacer()
                        Text(account.totalProfitLoss.formattedCurrency(currency: account.currency))
                            .foregroundStyle(account.totalProfitLoss >= 0 ? .incomeGreen : .expenseRed)
                    }
                    HStack {
                        Text("Current Value")
                            .font(.headline)
                        Spacer()
                        Text(account.currentValue.formattedCurrency(currency: account.currency))
                            .font(.headline)
                    }
                    HStack {
                        Text("Return")
                        Spacer()
                        Text("\(account.returnPercentage)")
                            .foregroundStyle(account.returnPercentage >= 0 ? .incomeGreen : .expenseRed)
                    }
                } else {
                    Text(account.currentBalance.formattedCurrency(currency: account.currency))
                        .font(.largeTitle.bold())
                    Text(account.initialBalance == account.currentBalance ? "Initial balance" : "From initial \(account.initialBalance.formattedCurrency(currency: account.currency))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var accountInfoSection: some View {
        Section("Info") {
            LabeledContent("Type", value: accountTypeLabel)
            if account.accountType == .bank {
                if let sub = account.bankSubType { LabeledContent("Sub Type", value: sub.rawValue.capitalized) }
                if let bank = account.bankName { LabeledContent("Bank", value: bank) }
                if let num = account.accountNumber { LabeledContent("Account #", value: num) }
            }
            if account.accountType == .cash, let sub = account.cashSubType {
                LabeledContent("Sub Type", value: sub.rawValue.capitalized)
            }
            if account.accountType == .psx, let broker = account.brokerName {
                LabeledContent("Broker", value: broker)
            }
            if account.accountType == .mutualFund, let house = account.fundHouse {
                LabeledContent("Fund House", value: house)
            }
            LabeledContent("Currency", value: account.currency)
            LabeledContent("Status", value: account.isActive ? "Active" : "Inactive")
            if let notes = account.notes, !notes.isEmpty {
                LabeledContent("Notes", value: notes)
            }
        }
    }

    private var investmentSection: some View {
        Section("Actions") {
            NavigationLink(destination: LogProfitLossView(account: account)) {
                Label("Log Profit / Loss", systemImage: "plus.forwardslash.minus")
            }
            NavigationLink(destination: AddCapitalView(account: account)) {
                Label("Add Capital", systemImage: "plus.circle")
            }
            NavigationLink(destination: WithdrawView(account: account)) {
                Label("Withdraw / Sell", systemImage: "arrow.up.right.circle")
            }
        }
    }

    private var recentTransactionsSection: some View {
        Section("Recent Transactions") {
            ForEach(Array(ledgerEntries.prefix(20))) { entry in
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.entryType == .debit ? "Debit" : "Credit")
                            .font(.headline)
                        Text(entry.date.formattedDate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(entry.amount.formattedCurrency(currency: account.currency))
                        Text("Balance: \(entry.runningBalance.formattedCurrency(currency: account.currency))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if ledgerEntries.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    private var accountTypeLabel: String {
        switch account.accountType {
        case .bank: return "Bank Account"
        case .cash: return "Cash"
        case .psx: return "PSX Stock Account"
        case .mutualFund: return "Mutual Fund Account"
        }
    }
}