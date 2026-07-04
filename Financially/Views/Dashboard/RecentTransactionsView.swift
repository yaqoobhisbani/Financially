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
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            } else {
                ForEach(transactions) { tx in
                    TransactionRowView(
                        transaction: tx,
                        accountName: accountName(for: tx.fromAccountId ?? tx.toAccountId),
                        showIcon: true
                    )
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