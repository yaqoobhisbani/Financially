import SwiftUI
import SwiftData

struct MFHoldingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let holding: MutualFundHolding

    @Query private var allTrades: [MutualFundTrade]
    @Query private var schemeList: [MutualFundScheme]
    @State private var showDeleteConfirmation = false
    @State private var showEditCYTD = false
    @State private var cytdValue = ""

    private var trades: [MutualFundTrade] {
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

                    HStack(alignment: .top) {
                        HStack(spacing: 16) {
                            SummaryMetric(label: "Units", value: holding.totalUnits.formattedNumber(), alignment: .leading)
                            SummaryMetric(label: "Avg NAV", value: holding.avgNavPrice.formattedCurrency(), alignment: .leading)
                        }
                        Spacer()
                        SummaryMetric(label: "Total Cost", value: holding.totalCost.formattedCurrency(), alignment: .trailing)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        SummaryMetric(label: "Unrealized P&L", value: holding.unrealizedPAndL.formattedCurrency(), color: holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let cytd = holding.cytdGainLoss {
                            SummaryMetric(label: "CYTD P&L", value: cytd.formattedCurrency(), color: cytd >= 0 ? .incomeGreen : .expenseRed, alignment: .trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    cytdValue = "\(cytd)"
                                    showEditCYTD = true
                                }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Trade History") {
                ForEach(trades) { trade in
                    TradeRowView(
                        type: trade.type,
                        detail: "\(trade.units.formattedNumber()) units @ \(trade.navPrice.formattedCurrency())",
                        date: trade.date,
                        netAmount: trade.netAmount.formattedCurrency(),
                        fee: trade.fees,
                        currency: "PKR"
                    )
                }

                if trades.isEmpty {
                    EmptyStateView(title: "No trades yet", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle(holding.schemeName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("CYTD Gain/Loss", isPresented: $showEditCYTD) {
            TextField("Amount", text: $cytdValue)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let value = Decimal(string: cytdValue) {
                    holding.cytdGainLoss = value
                    try? modelContext.save()
                }
            }
            Button("Clear") {
                holding.cytdGainLoss = nil
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Update CYTD gain/loss for \(holding.schemeName)")
        }
    }
}
