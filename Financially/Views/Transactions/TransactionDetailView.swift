import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    let transaction: Transaction

    @Query private var allAccounts: [Account]
    @Query private var allEntries: [LedgerEntry]

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
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
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