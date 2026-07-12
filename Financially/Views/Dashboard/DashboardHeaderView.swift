import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel
    var foreground: Color = .white

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    Text("Net Worth")
                }
                .font(.subheadline)
                .foregroundStyle(foreground.opacity(0.75))
                Text(vm.totalOwnFunds.formattedCurrency())
                    .font(.moneyHero)
                    .tabularNumbers()
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if vm.monthlyIncome > 0 || vm.monthlyExpense > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: vm.netFlowThisMonth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(abs(vm.netFlowThisMonth).formattedCurrency())
                        Text("this month · \(vm.netFlowThisMonth >= 0 ? "+" : "-")\(abs(vm.netFlowPercentage).formatted(.number.precision(.fractionLength(1))))%")
                            .foregroundStyle(foreground.opacity(0.75))
                    }
                    .font(.subheadline.weight(.semibold))
                    .tabularNumbers()
                    .foregroundStyle(foreground)
                    .padding(.top, 2)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HeaderStat(title: "In Accounts", amount: vm.totalAccounts, icon: "building.columns.fill", foreground: foreground)
                HeaderStat(title: "Invested", amount: vm.totalInvested, icon: "chart.line.uptrend.xyaxis", foreground: foreground)
                HeaderStat(title: "Liabilities", amount: vm.totalLiabilities, icon: "arrow.right.circle.fill", foreground: foreground)
                HeaderStat(title: "Receivables", amount: vm.totalReceivables, icon: "arrow.left.circle.fill", foreground: foreground)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, DesignSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

private struct HeaderStat: View {
    let title: String
    let amount: Decimal
    let icon: String
    var foreground: Color = .white

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(foreground.opacity(0.85))
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(foreground.opacity(0.65))
                Text(amount.formattedCurrency())
                    .font(.caption.bold())
                    .tabularNumbers()
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
