import SwiftUI

struct LedgerRowView: View {
    let entry: LedgerEntry
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.isInflow ? Color.incomeGreen.opacity(0.15) : Color.expenseRed.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.isInflow ? "arrow.down" : "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(entry.isInflow ? .incomeGreen : .expenseRed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedLabel)
                    .font(.subheadline.weight(.semibold))
                Text(entry.date.formattedDateTime())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.amount.formattedCurrency(currency: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.isInflow ? .incomeGreen : .expenseRed)
                Text(entry.runningBalance.formattedCurrency(currency: currency))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}