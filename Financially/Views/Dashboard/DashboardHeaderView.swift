import SwiftUI

struct DashboardHeaderView: View {
    let vm: DashboardViewModel
    let heroHeight: CGFloat

    @State private var netWorthMinY: CGFloat = 0

    private var netWorthTitleColor: Color {
        netWorthMinY < heroHeight ? .white.opacity(0.8) : .secondary
    }

    private var netWorthAmountColor: Color {
        netWorthMinY < heroHeight ? .white : .primary
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
                HeaderStat(title: "In Accounts", amount: vm.totalAccounts, icon: "building.columns.fill", heroHeight: heroHeight)
                HeaderStat(title: "Invested", amount: vm.totalInvested, icon: "chart.line.uptrend.xyaxis", heroHeight: heroHeight)
                HeaderStat(title: "Liabilities", amount: vm.totalLiabilities, icon: "arrow.right.circle.fill", heroHeight: heroHeight)
                HeaderStat(title: "Receivables", amount: vm.totalReceivables, icon: "arrow.left.circle.fill", heroHeight: heroHeight)
            }
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
    let heroHeight: CGFloat

    @State private var minY: CGFloat = 0

    private var textColor: Color {
        minY < heroHeight ? .white : .primary
    }

    private var secondaryTextColor: Color {
        minY < heroHeight ? .white.opacity(0.7) : .secondary
    }

    private var iconColor: Color {
        minY < heroHeight ? .white.opacity(0.9) : .secondary
    }

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
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { minY = proxy.frame(in: .global).minY }
                .onChange(of: proxy.frame(in: .global).minY) { _, v in minY = v }
        })
        .animation(.easeInOut(duration: 0.15), value: minY)
    }
}
