import SwiftUI
import SwiftData

struct AccountDetailView: View {
    let account: Account

    var body: some View {
        Group {
            switch account.accountType {
            case .psx:
                PSXAccountDetailView(account: account)
            case .bank, .cash:
                BankCashAccountDetailView(account: account)
            }
        }
    }
}

struct BankCashAccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @Query(sort: \LedgerEntry.date, order: .reverse) private var allLedgerEntries: [LedgerEntry]
    @Query private var allTransactions: [Transaction]
    @State private var showStatement = false
    @State private var showEdit = false
    @State private var selectedTransaction: Transaction?

    private var ledgerEntries: [LedgerEntry] {
        allLedgerEntries.filter { $0.accountId == account.id }
    }

    var body: some View {
        List {
            balanceSection
            recentTransactionsSection
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showEdit) {
            EditAccountView(account: account)
        }
    }

    // MARK: - Balance

    private var balanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.currentBalance.formattedCurrency(currency: account.currency))
                    .font(.largeTitle.bold())
                Text(account.initialBalance == account.currentBalance ? "Initial balance" : "From initial \(account.initialBalance.formattedCurrency(currency: account.currency))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        Section("Recent Transactions") {
            ForEach(Array(ledgerEntries.prefix(20))) { entry in
                LedgerRowView(entry: entry, currency: account.currency)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTransaction = allTransactions.first { $0.id == entry.transactionId }
                    }
            }

            if ledgerEntries.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack {
                TransactionDetailView(transaction: tx)
            }
        }
    }
}