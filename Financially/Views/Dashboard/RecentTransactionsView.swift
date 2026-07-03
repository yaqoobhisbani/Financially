import SwiftUI
import SwiftData

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    @State private var selectedTransaction: Transaction?

    @Query private var allAccounts: [Account]

    private func accountName(for id: UUID?) -> String {
        allAccounts.first { $0.id == id }?.name ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Transactions")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            if transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(transactions) { tx in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(txColor(tx.type).opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: txIcon(tx.type))
                                    .font(.caption)
                                    .foregroundStyle(txColor(tx.type))
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(txTypeLabel(tx.type))
                                .font(.subheadline.weight(.medium))
                            Text(accountName(for: tx.fromAccountId ?? tx.toAccountId))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(tx.amount.formattedCurrency())
                                .font(.subheadline.bold())
                                .foregroundStyle(tx.type == .income || tx.type == .loanRepayment || tx.type == .liabilityReceived ? .incomeGreen : .expenseRed)
                            Text(tx.date.formattedDate())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTransaction = tx }

                    if tx.id != transactions.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack {
                TransactionDetailView(transaction: tx)
            }
        }
    }

    private func txIcon(_ type: TransactionType) -> String {
        switch type {
        case .income: return "arrow.down.circle"
        case .expense: return "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .loanGiven: return "arrow.right.circle"
        case .loanRepayment: return "arrow.left.circle"
        case .liabilityReceived: return "arrow.down.circle"
        case .liabilityPayback: return "arrow.up.circle"
        case .investmentWithdrawal: return "arrow.up.right.circle"
        case .investmentAddCapital: return "plus.circle"
        case .investmentProfitLoss: return "chart.line.uptrend.xyaxis"
        }
    }

    private func txColor(_ type: TransactionType) -> Color {
        switch type {
        case .income, .loanRepayment, .liabilityReceived: return .incomeGreen
        case .expense, .loanGiven, .liabilityPayback: return .expenseRed
        case .transfer, .investmentAddCapital: return .blue
        case .investmentWithdrawal: return .orange
        case .investmentProfitLoss: return .purple
        }
    }

    private func txTypeLabel(_ type: TransactionType) -> String {
        switch type {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .loanGiven: return "Loan Given"
        case .loanRepayment: return "Repayment"
        case .liabilityReceived: return "Received (Liability)"
        case .liabilityPayback: return "Payback"
        case .investmentWithdrawal: return "Withdrawal"
        case .investmentAddCapital: return "Add Capital"
        case .investmentProfitLoss: return "P&L Entry"
        }
    }
}