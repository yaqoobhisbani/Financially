import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction

    @Query private var allAccounts: [Account]
    @Query private var allEntries: [LedgerEntry]

    @State private var showDeleteConfirmation = false

    private var entries: [LedgerEntry] {
        allEntries.filter { $0.transactionId == transaction.id }
    }

    private var sourceAccount: Account? {
        allAccounts.first { $0.id == transaction.fromAccountId }
    }

    private var destinationAccount: Account? {
        allAccounts.first { $0.id == transaction.toAccountId }
    }

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Type", value: transaction.type.displayLabel)
                LabeledContent("Amount", value: transaction.amount.formattedCurrency())
                LabeledContent("Date", value: transaction.date.formattedDate())
                if let category = transaction.category {
                    LabeledContent("Category", value: category)
                }
                if let description = transaction.desc {
                    LabeledContent("Description", value: description)
                }
            }

            Section("Accounts") {
                if let source = sourceAccount {
                    LabeledContent("From", value: source.name)
                }
                if let dest = destinationAccount {
                    LabeledContent("To", value: dest.name)
                }
            }

            Section("Ledger Entries") {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.entryType == .debit ? "Debit" : "Credit")
                            .font(.headline)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(entry.amount.formattedCurrency())
                            Text("Running: \(entry.runningBalance.formattedCurrency())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Transaction", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteTransaction() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this transaction? This will reverse all ledger entries, account balances, and related debtor/creditor amounts.")
        }
    }

    // MARK: - Actions

    private func deleteTransaction() {
        let manager = LedgerManager(modelContext: modelContext)
        try? manager.deleteTransaction(transaction)
        dismiss()
    }
}
