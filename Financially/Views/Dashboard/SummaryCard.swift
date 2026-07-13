import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color
    var subtitle: String?
    var valueColored: Bool = false
    var sparkline: [Decimal]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(amount.formattedCurrency())
                .font(.moneyTitle)
                .tabularNumbers()
                .foregroundStyle(valueColored ? color : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let sparkline, sparkline.count >= 2 {
                SparklineView(values: sparkline, tint: color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .dashboardCard()
    }
}
