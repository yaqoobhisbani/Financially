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
                            .fill(tx.type.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: tx.type.icon)
                                    .font(.caption)
                                    .foregroundStyle(tx.type.color)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.type.displayLabel)
                                .font(.subheadline.weight(.medium))
                            Text(accountName(for: tx.fromAccountId ?? tx.toAccountId))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(tx.amount.formattedCurrency())
                                .font(.subheadline.bold())
                                .foregroundStyle(tx.type.amountColor)
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
}