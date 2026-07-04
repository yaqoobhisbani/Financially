import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction

    @Query private var allAccounts: [Account]
    @Query private var allEntries: [LedgerEntry]
    @Query private var allTransactions: [Transaction]

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
                LabeledContent("Type", value: transactionTypeLabel)
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
            Text("Are you sure you want to delete this transaction? This will reverse all ledger entries.")
        }
    }

    // MARK: - Actions

    private func deleteTransaction() {
        reverseLedgerEntries()
        reverseAccountBalances()
        reverseRelatedEntity()
        modelContext.delete(transaction)
        try? modelContext.save()
        dismiss()
    }

    private func reverseLedgerEntries() {
        for entry in entries {
            modelContext.delete(entry)
        }
    }

    private func reverseAccountBalances() {
        let amount = transaction.amount
        switch transaction.type {
        case .expense:
            sourceAccount?.currentBalance += amount
        case .income:
            destinationAccount?.currentBalance -= amount
        case .transfer:
            sourceAccount?.currentBalance += amount
            destinationAccount?.currentBalance -= amount
        case .loanGiven:
            sourceAccount?.currentBalance += amount
        case .loanRepayment:
            destinationAccount?.currentBalance -= amount
        case .liabilityReceived:
            destinationAccount?.currentBalance -= amount
        case .liabilityPayback:
            sourceAccount?.currentBalance += amount
        case .investmentAddCapital:
            sourceAccount?.currentBalance += amount
            destinationAccount?.currentBalance -= amount
        case .investmentWithdrawal:
            destinationAccount?.currentBalance -= amount
            sourceAccount?.currentBalance += amount
        case .investmentProfitLoss:
            destinationAccount?.currentBalance -= amount
        }
    }

    private func reverseRelatedEntity() {
        guard let entityId = transaction.relatedEntityId else { return }

        switch transaction.type {
        case .loanGiven:
            let fetch = FetchDescriptor<Debtor>(predicate: #Predicate { $0.id == entityId })
            if let debtor = try? modelContext.fetch(fetch).first {
                debtor.totalLent -= transaction.amount
                debtor.updatedAt = Date()
            }
        case .loanRepayment:
            let fetch = FetchDescriptor<Debtor>(predicate: #Predicate { $0.id == entityId })
            if let debtor = try? modelContext.fetch(fetch).first {
                debtor.totalRepaid -= transaction.amount
                debtor.updatedAt = Date()
            }
        case .liabilityReceived:
            let fetch = FetchDescriptor<Creditor>(predicate: #Predicate { $0.id == entityId })
            if let creditor = try? modelContext.fetch(fetch).first {
                creditor.totalReceived -= transaction.amount
                creditor.updatedAt = Date()
            }
        case .liabilityPayback:
            let fetch = FetchDescriptor<Creditor>(predicate: #Predicate { $0.id == entityId })
            if let creditor = try? modelContext.fetch(fetch).first {
                creditor.totalReturned -= transaction.amount
                creditor.updatedAt = Date()
            }
        default:
            break
        }
    }

    private var transactionTypeLabel: String {
        switch transaction.type {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .investmentWithdrawal: return "Investment Withdrawal"
        case .investmentAddCapital: return "Add Capital"
        case .loanGiven: return "Loan Given"
        case .loanRepayment: return "Loan Repayment"
        case .liabilityReceived: return "Liability Received"
        case .liabilityPayback: return "Liability Payback"
        case .investmentProfitLoss: return "Investment P&L"
        }
    }
}