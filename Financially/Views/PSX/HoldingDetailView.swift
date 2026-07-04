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
                SummaryBalanceView(
                    heroLeftLabel: "Current Value",
                    heroLeftValue: holding.currentValue.formattedCurrency(currency: account.currency),
                    heroRightLabel: "Return",
                    heroRightValue: holding.returnPercentage.formatted(.number.precision(.fractionLength(2))) + "%",
                    heroRightColor: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed,
                    detailRows: [
                        [
                            SummaryMetric(label: "Shares", value: "\(holding.totalShares)"),
                            SummaryMetric(label: "Avg Cost", value: holding.avgCostPerShare.formattedCurrency(currency: account.currency)),
                            SummaryMetric(label: "Total Cost", value: holding.totalCost.formattedCurrency(currency: account.currency))
                        ],
                        [
                            SummaryMetric(label: "Unrealized P&L", value: holding.unrealizedPAndL.formattedCurrency(currency: account.currency), color: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed),
                            SummaryMetric(label: "Fees Paid", value: holding.totalFeesPaid.formattedCurrency(currency: account.currency), color: .secondary)
                        ]
                    ]
                )
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