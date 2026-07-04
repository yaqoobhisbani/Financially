import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    var accountName: String? = nil
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            if showIcon {
                Circle()
                    .fill(transaction.type.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: transaction.type.icon)
                            .font(.caption)
                            .foregroundStyle(transaction.type.color)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.type.displayLabel)
                    .font(showIcon ? .subheadline.weight(.medium) : .headline)
                if let accountName {
                    Text(accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let desc = transaction.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount.formattedCurrency())
                    .font(showIcon ? .subheadline.bold() : .subheadline)
                    .foregroundStyle(transaction.type.amountColor)
                Text(transaction.date.formattedDate())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let category = transaction.category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
