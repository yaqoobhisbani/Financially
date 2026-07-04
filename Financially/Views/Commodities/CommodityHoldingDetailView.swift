import SwiftUI
import SwiftData

struct CommodityHoldingDetailView: View {
    let holding: CommodityHolding

    @Query private var allTrades: [CommodityTrade]

    private var trades: [CommodityTrade] {
        allTrades
            .filter { $0.holdingId == holding.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Summary") {
                SummaryBalanceView(
                    heroLeftLabel: "Current Value",
                    heroLeftValue: holding.currentValue.formattedCurrency(),
                    heroRightLabel: "Return",
                    heroRightValue: holding.returnPercentage.formatted(.number.precision(.fractionLength(2))) + "%",
                    heroRightColor: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed,
                    detailRows: [
                        [
                            SummaryMetric(label: "Grams", value: holding.totalGrams.formattedNumber()),
                            SummaryMetric(label: "Avg Cost/g", value: holding.avgCostPerGram.formattedCurrency()),
                            SummaryMetric(label: "Total Cost", value: holding.totalCost.formattedCurrency())
                        ],
                        [
                            SummaryMetric(label: "Unrealized P&L", value: holding.unrealizedPAndL.formattedCurrency(), color: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed),
                            SummaryMetric(label: "Fees Paid", value: holding.totalFeesPaid.formattedCurrency(), color: .secondary)
                        ]
                    ]
                )
            }

            Section("Trade History") {
                ForEach(trades) { trade in
                    TradeRowView(
                        type: trade.type,
                        detail: "\(trade.grams.formattedNumber()) g @ \(trade.pricePerGram.formattedCurrency())",
                        date: trade.date,
                        netAmount: trade.netAmount.formattedCurrency(),
                        fee: trade.brokerageFee + trade.tax
                    )
                }

                if trades.isEmpty {
                    EmptyStateView(title: "No trades yet", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle(holding.commodityName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
