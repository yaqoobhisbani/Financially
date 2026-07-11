import Foundation
import AppIntents
import SwiftData

struct BuySharesIntent: AppIntent {
    static var title: LocalizedStringResource = "Buy Shares"
    static var description: LocalizedStringResource = "Buy shares in a PSX account"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "PSX Account", requestValueDialog: "In which PSX account?")
    var account: PSXAccountEntity

    @Parameter(title: "Stock", requestValueDialog: "Which stock?")
    var stock: StockEntity

    @Parameter(title: "Shares", requestValueDialog: "How many shares?")
    var shares: Int

    @Parameter(title: "Price Per Share", requestValueDialog: "At what price per share?")
    var pricePerShare: Double

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let accountId = account.id
        let stockId = stock.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let acct = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountId })).first else {
                throw IntentError.failed("PSX account not found.")
            }
            guard let stockInfo = try? context.fetch(FetchDescriptor<StockInfo>(predicate: #Predicate { $0.id == stockId })).first else {
                throw IntentError.failed("Stock not found.")
            }

            let total = Decimal(shares) * Decimal(pricePerShare)
            let allHoldings = (try? context.fetch(FetchDescriptor<StockHolding>())) ?? []
            let holding: StockHolding
            if let existing = allHoldings.first(where: { $0.ticker == stockInfo.ticker && $0.accountId == acct.id }) {
                holding = existing
            } else {
                holding = StockHolding(accountId: acct.id, companyName: stockInfo.companyName, ticker: stockInfo.ticker)
                context.insert(holding)
            }

            if holding.currentPrice == nil, stockInfo.currentRate > 0 {
                holding.currentPrice = stockInfo.currentRate
                holding.priceFetchedAt = Date()
            }

            let trade = StockTrade(
                accountId: acct.id, holdingId: holding.id, type: .buy,
                ticker: stockInfo.ticker, companyName: stockInfo.companyName,
                shares: shares, pricePerShare: Decimal(pricePerShare),
                totalAmount: total, brokerageFee: 0, tax: 0, netAmount: total,
                date: date ?? Date(), notes: notes
            )
            context.insert(trade)

            let update = TradeService.weightedAverageBuyInt(
                currentQuantity: holding.totalShares, currentCost: holding.totalCost,
                currentFees: holding.totalFeesPaid, addedQuantity: shares,
                addedCost: total, addedFees: 0)
            holding.totalShares = update.quantity; holding.totalCost = update.cost
            holding.totalFeesPaid = update.fees; holding.avgCostPerShare = update.avgCost

            acct.currentBalance -= total
            let all = (try? context.fetch(FetchDescriptor<StockHolding>())) ?? []
            acct.syncFromHoldings(all.filter { $0.accountId == acct.id })
            acct.updatedAt = Date()

            let tx = insertStockTransaction(context: context, type: .stockBuy, amount: total, date: date ?? Date(),
                              description: notes ?? "Buy \(stockInfo.companyName) (\(stockInfo.ticker))", psxAccountId: acct.id, psxAccountBalance: acct.currentBalance)
            trade.transactionId = tx.id
            try context.save()

            return .result(dialog: "Bought \(shares) shares of \(stockInfo.ticker) for Rs \(total.formatted(.number.precision(.fractionLength(0...2)))).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
