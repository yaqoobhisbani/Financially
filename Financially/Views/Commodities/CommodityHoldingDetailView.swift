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
                        VStack(alignment: .leading) {
                            Text("Current Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.currentValue.formattedCurrency())
                                .font(.title.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Return")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(returnFormatted)
                                .font(.title3.bold())
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Grams")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.totalGrams.formattedNumber())
                                .font(.body.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Avg Cost/g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.avgCostPerGram.formattedCurrency())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Total Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.totalCost.formattedCurrency())
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Unrealized P&L")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.unrealizedPAndL.formattedCurrency())
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Fees Paid")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.totalFeesPaid.formattedCurrency())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Trade History") {
                ForEach(trades) { trade in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(trade.type == .buy ? "Buy" : "Sell")
                                    .font(.headline)
                                    .foregroundStyle(trade.type == .buy ? .incomeGreen : .expenseRed)
                                Text("\(trade.grams.formattedNumber()) g @ \(trade.pricePerGram.formattedCurrency())")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(trade.date.formattedDate())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(trade.netAmount.formattedCurrency())
                                .font(.subheadline.bold())
                            if trade.brokerageFee > 0 || trade.tax > 0 {
                                Text("Fee: \((trade.brokerageFee + trade.tax).formattedCurrency())")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if trades.isEmpty {
                    Text("No trades yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .navigationTitle(holding.commodityName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var returnFormatted: String {
        let percentage = holding.returnPercentage
        return percentage.formatted(.number.precision(.fractionLength(2))) + "%"
    }
}
