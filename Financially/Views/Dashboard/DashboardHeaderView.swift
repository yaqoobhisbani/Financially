import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(vm.totalOwnFunds.formattedCurrency())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HeaderStat(
                    title: "In Accounts",
                    amount: vm.totalAccounts,
                    icon: "building.columns.fill",
                    color: .blue
                )
                HeaderStat(
                    title: "Invested",
                    amount: vm.totalInvested,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
                HeaderStat(
                    title: "Liabilities",
                    amount: vm.totalLiabilities,
                    icon: "arrow.right.circle.fill",
                    color: .orange
                )
                HeaderStat(
                    title: "Receivables",
                    amount: vm.totalReceivables,
                    icon: "arrow.left.circle.fill",
                    color: .teal
                )
            }
        }
        .padding()
        .liquidGlassCard()
    }
}

private struct HeaderStat: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(amount.formattedCurrency())
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
