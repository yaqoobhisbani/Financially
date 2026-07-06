import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel
    let heroHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(vm.totalOwnFunds.formattedCurrency())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                headerStat(title: "In Accounts", amount: vm.totalAccounts, icon: "building.columns.fill", color: .white)
                headerStat(title: "Invested", amount: vm.totalInvested, icon: "chart.line.uptrend.xyaxis", color: .white)
                headerStat(title: "Liabilities", amount: vm.totalLiabilities, icon: "arrow.right.circle.fill", color: .white)
                headerStat(title: "Receivables", amount: vm.totalReceivables, icon: "arrow.left.circle.fill", color: .white)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .frame(height: heroHeight)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "#2563EB") ?? .blue, Color(hex: "#1D4ED8") ?? Color(red: 0.11, green: 0.31, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private func headerStat(title: String, amount: Decimal, icon: String, color: Color) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(color.opacity(0.9))
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
