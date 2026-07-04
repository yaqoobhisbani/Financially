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
                        VStack(alignment: .leading) {
                            Text("Current Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.currentValue.formattedCurrency(currency: account.currency))
                                .font(.title.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Return")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            PercentageText(value: holding.returnPercentage)
                                .font(.title3.bold())
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Shares")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(holding.totalShares)")
                                .font(.body.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Avg Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.avgCostPerShare.formattedCurrency(currency: account.currency))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Total Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.totalCost.formattedCurrency(currency: account.currency))
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Unrealized P&L")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.unrealizedPAndL.formattedCurrency(currency: account.currency))
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Fees Paid")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(holding.totalFeesPaid.formattedCurrency(currency: account.currency))
                                .foregroundStyle(.secondary)
                        }
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
                    Text("No trades yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .navigationTitle(holding.ticker)
        .navigationBarTitleDisplayMode(.inline)
    }
}