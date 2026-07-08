import SwiftUI
import SwiftData

struct MFHoldingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let holding: MutualFundHolding

    @Query private var allTrades: [MutualFundTrade]
    @Query private var schemeList: [MutualFundScheme]
    @Query private var allTransactions: [Transaction]
    @State private var showDeleteConfirmation = false
    @State private var tradeToDelete: MutualFundTrade?
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
                            SummaryMetric(label: "Avg NAV", value: holding.avgNavPrice.formattedNAVPrice(), alignment: .leading)
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
                        detail: "\(trade.units.formattedNumber()) units @ \(trade.navPrice.formattedNAVPrice())",
                        date: trade.date,
                        netAmount: trade.netAmount.formattedCurrency(),
                        fee: trade.fees,
                        currency: "PKR"
                    )
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            tradeToDelete = trade
                        }
                    }
                }

                if trades.isEmpty {
                    EmptyStateView(title: "No trades yet", systemImage: "arrow.left.arrow.right")
                }
            }
        }
        .navigationTitle(holding.schemeName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Trade", isPresented: .init(
            get: { tradeToDelete != nil },
            set: { if !$0 { tradeToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let trade = tradeToDelete {
                    deleteTrade(trade)
                }
                tradeToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tradeToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this trade? This action cannot be undone.")
        }
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

    private func deleteTrade(_ trade: MutualFundTrade) {
        let remaining = trades.filter { $0.id != trade.id }

        let relatedTxs = allTransactions.filter { $0.relatedEntityId == account.id }
        if trade.type == .buy {
            if let tx = relatedTxs.first(where: { $0.fromAccountId != account.id && $0.type == .mutualFundBuy }) {
                if let bankId = tx.fromAccountId,
                   let bank = try? modelContext.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankId })).first {
                    bank.currentBalance += trade.netAmount
                    bank.updatedAt = Date()
                }
                modelContext.delete(tx)
            }
        } else {
            if let tx = relatedTxs.first(where: { $0.toAccountId != account.id && $0.type == .mutualFundSell }) {
                if let bankId = tx.toAccountId,
                   let bank = try? modelContext.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankId })).first {
                    bank.currentBalance -= trade.netAmount
                    bank.updatedAt = Date()
                }
                modelContext.delete(tx)
            }
        }
        modelContext.delete(trade)

        let result = TradeService.recalculateMFHolding(trades: remaining)
        holding.totalUnits = result.totalUnits
        holding.totalCost = result.totalCost
        holding.avgNavPrice = result.avgNavPrice

        let all = (try? modelContext.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
        account.syncFromMFHoldings(all.filter { $0.accountId == account.id })
        account.updatedAt = Date()

        try? modelContext.save()
    }
}
