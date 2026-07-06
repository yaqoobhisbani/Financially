import SwiftUI
import SwiftData

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let onViewAll: (() -> Void)?
    @State private var selectedTransaction: Transaction?

    @Query private var allAccounts: [Account]

    init(transactions: [Transaction], onViewAll: (() -> Void)? = nil) {
        self.transactions = transactions
        self.onViewAll = onViewAll
    }

    private func accountName(for id: UUID?) -> String {
        allAccounts.first { $0.id == id }?.name ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                if let onViewAll {
                    Button("View All", action: onViewAll)
                        .font(.subheadline)
                }
            }
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
        .padding(.vertical, 12)
        .liquidGlassCard()
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack {
                TransactionDetailView(transaction: tx)
            }
        }
    }
}