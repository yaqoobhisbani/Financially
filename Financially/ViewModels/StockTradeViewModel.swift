import Foundation
import SwiftData

@Observable
final class StockTradeViewModel {
    private let modelContext: ModelContext
    let account: Account
    let stockList: [StockInfo]
    let holdings: [StockHolding]

    init(modelContext: ModelContext, account: Account, stockList: [StockInfo], holdings: [StockHolding]) {
        self.modelContext = modelContext
        self.account = account
        self.stockList = stockList
        self.holdings = holdings
    }

    var accountHoldings: [StockHolding] {
        holdings.filter { $0.accountId == account.id && $0.totalShares > 0 }
    }

    func findOrCreateHolding(ticker: String, companyName: String) -> StockHolding {
        if let existing = holdings.first(where: { $0.ticker == ticker && $0.accountId == account.id }) {
            return existing
        }
        let holding = StockHolding(accountId: account.id, companyName: companyName, ticker: ticker)
        modelContext.insert(holding)
        return holding
    }

    func buy(ticker: String, companyName: String, shares: Int, pricePerShare: Decimal, brokerageFee: Decimal, tax: Decimal, netAmount: Decimal, date: Date, notes: String?) {
        let holding = findOrCreateHolding(ticker: ticker, companyName: companyName)

        if holding.currentPrice == nil, let stock = stockList.first(where: { $0.ticker == ticker }), stock.currentRate > 0 {
            holding.currentPrice = stock.currentRate
            holding.priceFetchedAt = Date()
        }

        let total = Decimal(shares) * pricePerShare
        let fees = brokerageFee + tax

        let trade = StockTrade(
            accountId: account.id,
            holdingId: holding.id,
            type: .buy,
            ticker: ticker,
            companyName: companyName,
            shares: shares,
            pricePerShare: pricePerShare,
            totalAmount: total,
            brokerageFee: brokerageFee,
            tax: tax,
            netAmount: netAmount,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let update = TradeService.weightedAverageBuyInt(
            currentQuantity: holding.totalShares,
            currentCost: holding.totalCost,
            currentFees: holding.totalFeesPaid,
            addedQuantity: shares,
            addedCost: total,
            addedFees: fees
        )
        holding.totalShares = update.quantity
        holding.totalCost = update.cost
        holding.totalFeesPaid = update.fees
        holding.avgCostPerShare = update.avgCost

        account.currentBalance -= netAmount
        syncAccountFromHoldings()
        account.updatedAt = Date()
        let transaction = createTransaction(type: .stockBuy, amount: netAmount, date: date, description: notes ?? "Buy \(companyName) (\(ticker))")
        trade.transactionId = transaction.id
    }

    func sell(holding: StockHolding, shares: Int, pricePerShare: Decimal, brokerageFee: Decimal, tax: Decimal, netProceeds: Decimal, date: Date, notes: String?) {
        let total = Decimal(shares) * pricePerShare
        let fees = brokerageFee + tax

        if holding.currentPrice == nil, let stock = stockList.first(where: { $0.ticker == holding.ticker }), stock.currentRate > 0 {
            holding.currentPrice = stock.currentRate
            holding.priceFetchedAt = Date()
        }

        let trade = StockTrade(
            accountId: account.id,
            holdingId: holding.id,
            type: .sell,
            ticker: holding.ticker,
            companyName: holding.companyName,
            shares: shares,
            pricePerShare: pricePerShare,
            totalAmount: total,
            brokerageFee: brokerageFee,
            tax: tax,
            netAmount: netProceeds,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let update = TradeService.weightedAverageSellInt(
            currentQuantity: holding.totalShares,
            currentCost: holding.totalCost,
            currentFees: holding.totalFeesPaid,
            soldQuantity: shares
        )
        holding.totalShares = update.quantity
        holding.totalCost = update.cost
        holding.totalFeesPaid = update.fees
        holding.avgCostPerShare = update.avgCost

        account.currentBalance += netProceeds
        syncAccountFromHoldings()
        account.updatedAt = Date()
        let transaction = createTransaction(type: .stockSell, amount: netProceeds, date: date, description: notes ?? "Sell \(holding.companyName) (\(holding.ticker))")
        trade.transactionId = transaction.id
    }

    @discardableResult
    private func createTransaction(type: TransactionType, amount: Decimal, date: Date, description: String) -> Transaction {
        let transaction = Transaction(
            type: type,
            amount: amount,
            date: date,
            description: description,
            fromAccountId: type == .stockBuy ? account.id : nil,
            toAccountId: type == .stockSell ? account.id : nil,
            relatedEntityId: account.id
        )
        modelContext.insert(transaction)

        let entry = LedgerEntry(
            transactionId: transaction.id,
            accountId: account.id,
            entryType: type == .stockBuy ? .debit : .credit,
            amount: amount,
            runningBalance: account.currentBalance,
            date: date
        )
        entry.account = account
        modelContext.insert(entry)
        return transaction
    }

    private func syncAccountFromHoldings() {
        let all = (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? []
        account.syncFromHoldings(all.filter { $0.accountId == account.id })
    }
}