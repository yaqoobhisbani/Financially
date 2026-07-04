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

        let newTotal = holding.totalShares + shares
        let newCost = holding.totalCost + total
        holding.totalShares = newTotal
        holding.totalCost = newCost
        holding.totalFeesPaid += fees
        holding.avgCostPerShare = newTotal > 0 ? newCost / Decimal(newTotal) : 0

        account.currentBalance -= netAmount
        syncAccountFromHoldings()
        account.updatedAt = Date()
    }

    func sell(holding: StockHolding, shares: Int, pricePerShare: Decimal, brokerageFee: Decimal, tax: Decimal, netProceeds: Decimal, date: Date, notes: String?) {
        let total = Decimal(shares) * pricePerShare
        let fees = brokerageFee + tax

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

        let remainingShares = holding.totalShares - shares
        if remainingShares == 0 {
            holding.totalShares = 0
            holding.totalCost = 0
            holding.avgCostPerShare = 0
        } else {
            let avgCostPerShare = holding.totalCost / Decimal(holding.totalShares)
            holding.totalCost -= Decimal(shares) * avgCostPerShare
            holding.totalShares = remainingShares
            holding.avgCostPerShare = holding.totalShares > 0 ? holding.totalCost / Decimal(holding.totalShares) : 0
        }
        holding.totalFeesPaid += fees

        account.currentBalance += netProceeds
        syncAccountFromHoldings()
        account.updatedAt = Date()
    }

    private func syncAccountFromHoldings() {
        let all = (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? []
        account.syncFromHoldings(all.filter { $0.accountId == account.id })
    }
}