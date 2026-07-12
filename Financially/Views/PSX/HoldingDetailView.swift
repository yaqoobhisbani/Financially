import SwiftUI
import SwiftData

struct HoldingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account
    let holding: StockHolding

    @Query private var allTrades: [StockTrade]
    @State private var showDeleteConfirmation = false
    @State private var tradeToDelete: StockTrade?

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
        .navigationTitle(holding.ticker)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .glassIconButton()
            }
        }
        .alert("Delete Holding", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteHolding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this holding and all its trades? This action cannot be undone.")
        }
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
    }

    private func deleteTrade(_ trade: StockTrade) {
        if let txnId = trade.transactionId,
           let transaction = try? modelContext.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnId })).first {
            let manager = LedgerManager(modelContext: modelContext)
            try? manager.deleteTransaction(transaction)
            return
        }

        // Legacy trades recorded before cash transactions were linked to trades.
        if trade.type == .buy {
            account.currentBalance += trade.netAmount
        } else {
            account.currentBalance -= trade.netAmount
        }
        modelContext.delete(trade)

        let remaining = trades.filter { $0.id != trade.id }
        let result = TradeService.recalculateStockHolding(trades: remaining)
        holding.totalShares = result.totalShares
        holding.totalCost = result.totalCost
        holding.totalFeesPaid = result.totalFeesPaid
        holding.avgCostPerShare = result.avgCostPerShare

        let all = (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? []
        account.syncFromHoldings(all.filter { $0.accountId == account.id })
        account.updatedAt = Date()

        try? modelContext.save()
    }

    private func deleteHolding() {
        let manager = LedgerManager(modelContext: modelContext)
        for trade in trades {
            if let txnId = trade.transactionId,
               let transaction = try? modelContext.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnId })).first {
                try? manager.deleteTransaction(transaction)
            } else {
                if trade.type == .buy {
                    account.currentBalance += trade.netAmount
                } else {
                    account.currentBalance -= trade.netAmount
                }
                modelContext.delete(trade)
            }
        }
        modelContext.delete(holding)

        let all = (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? []
        account.syncFromHoldings(all.filter { $0.accountId == account.id })
        account.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}
