import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(vm.totalOwnFunds.formattedCurrency())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HeaderStat(title: "In Accounts", amount: vm.totalAccounts, icon: "building.columns.fill")
                HeaderStat(title: "Invested", amount: vm.totalInvested, icon: "chart.line.uptrend.xyaxis")
                HeaderStat(title: "Liabilities", amount: vm.totalLiabilities, icon: "arrow.right.circle.fill")
                HeaderStat(title: "Receivables", amount: vm.totalReceivables, icon: "arrow.left.circle.fill")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

private struct HeaderStat: View {
    let title: String
    let amount: Decimal
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text(amount.formattedCurrency())
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
