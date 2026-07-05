import SwiftUI
import SwiftData

struct HoldingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account
    let holding: StockHolding

    @Query private var allTrades: [StockTrade]

    private var trades: [StockTrade] {
        allTrades
            .filter { $0.holdingId == holding.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Summary") {
                VStack(spacing: 12) {
                    HStack {
                        SummaryMetric(
                            label: "Current Value",
                            value: holding.currentValue.formattedCurrency(currency: account.currency),
                            valueFont: .title.bold()
                        )
                        Spacer()
                        SummaryMetricView(label: "Return", alignment: .trailing) {
                            PercentageText(value: holding.returnPercentage)
                                .font(.title3.bold())
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    Divider()

                    HStack(alignment: .top) {
                        HStack(spacing: 16) {
                            SummaryMetric(label: "Shares", value: "\(holding.totalShares)", alignment: .leading)
                            SummaryMetric(label: "Avg Cost", value: holding.avgCostPerShare.formattedCurrency(currency: account.currency), alignment: .leading)
                        }
                        Spacer()
                        SummaryMetric(label: "Total Cost", value: holding.totalCost.formattedCurrency(currency: account.currency), alignment: .trailing)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        SummaryMetric(label: "Unrealized P&L", value: holding.unrealizedPAndL.formattedCurrency(currency: account.currency), color: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SummaryMetric(label: "Fees Paid", value: holding.totalFeesPaid.formattedCurrency(currency: account.currency), color: .secondary, alignment: .trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Trade History") {
                ForEach(trades) { trade in
                    TradeRowView(
                        type: trade.type,
                        detail: "\(trade.shares) shares @ \(trade.pricePerShare.formattedCurrency(currency: account.currency))",
                        date: trade.date,
                        netAmount: trade.netAmount.formattedCurrency(currency: account.currency),
                        fee: trade.brokerageFee + trade.tax,
                        currency: account.currency
                    )
                }

                if trades.isEmpty {
                    EmptyStateView(title: "No trades yet", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle(holding.ticker)
        .navigationBarTitleDisplayMode(.inline)
    }
}