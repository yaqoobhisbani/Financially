import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel
    let heroHeight: CGFloat

    @State private var netWorthMinY: CGFloat = 0
    @State private var gridMinY: CGFloat = 0

    private var netWorthTitleColor: Color {
        netWorthMinY < heroHeight ? .white.opacity(0.8) : .secondary
    }

    private var netWorthAmountColor: Color {
        netWorthMinY < heroHeight ? .white : .primary
    }

    private var textColor: Color {
        gridMinY < heroHeight ? .white : .primary
    }

    private var secondaryTextColor: Color {
        gridMinY < heroHeight ? .white.opacity(0.7) : .secondary
    }

    private var iconColor: Color {
        gridMinY < heroHeight ? .white.opacity(0.9) : .secondary
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    Text("Net Worth")
                }
                .font(.subheadline)
                .foregroundStyle(netWorthTitleColor)
                Text(vm.totalOwnFunds.formattedCurrency())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(netWorthAmountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear { netWorthMinY = proxy.frame(in: .global).minY }
                    .onChange(of: proxy.frame(in: .global).minY) { _, v in netWorthMinY = v }
            })
            .animation(.easeInOut(duration: 0.15), value: netWorthMinY)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HeaderStat(title: "In Accounts", amount: vm.totalAccounts, icon: "building.columns.fill", textColor: textColor, secondaryTextColor: secondaryTextColor, iconColor: iconColor)
                HeaderStat(title: "Invested", amount: vm.totalInvested, icon: "chart.line.uptrend.xyaxis", textColor: textColor, secondaryTextColor: secondaryTextColor, iconColor: iconColor)
                HeaderStat(title: "Liabilities", amount: vm.totalLiabilities, icon: "arrow.right.circle.fill", textColor: textColor, secondaryTextColor: secondaryTextColor, iconColor: iconColor)
                HeaderStat(title: "Receivables", amount: vm.totalReceivables, icon: "arrow.left.circle.fill", textColor: textColor, secondaryTextColor: secondaryTextColor, iconColor: iconColor)
            }
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear { gridMinY = proxy.frame(in: .global).minY }
                    .onChange(of: proxy.frame(in: .global).minY) { _, v in gridMinY = v }
            })
            .animation(.easeInOut(duration: 0.15), value: gridMinY)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 0)
    }
}

private struct HeaderStat: View {
    let title: String
    let amount: Decimal
    let icon: String
    let textColor: Color
    let secondaryTextColor: Color
    let iconColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(secondaryTextColor)
                Text(amount.formattedCurrency())
                    .font(.caption.bold())
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
