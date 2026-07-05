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
                VStack(spacing: 12) {
                    HStack {
                        SummaryMetric(
                            label: "Current Value",
                            value: holding.currentValue.formattedCurrency(),
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

                    HStack(alignment: .top, spacing: 16) {
                        SummaryMetric(label: "Grams", value: holding.totalGrams.formattedNumber(), alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SummaryMetric(label: "Avg Cost/g", value: holding.avgCostPerGram.formattedCurrency(), alignment: .center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        SummaryMetric(label: "Total Cost", value: holding.totalCost.formattedCurrency(), alignment: .trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        SummaryMetric(label: "Unrealized P&L", value: holding.unrealizedPAndL.formattedCurrency(), color: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SummaryMetric(label: "Fees Paid", value: holding.totalFeesPaid.formattedCurrency(), color: .secondary, alignment: .trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, 8)
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
