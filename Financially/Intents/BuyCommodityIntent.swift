import Foundation
import AppIntents
import SwiftData

struct BuyCommodityIntent: AppIntent {
    static var title: LocalizedStringResource = "Buy Commodity"
    static var description: LocalizedStringResource = "Buy gold or silver"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Commodity", requestValueDialog: "Which commodity?")
    var commodity: CommodityEntity

    @Parameter(title: "Grams", requestValueDialog: "How many grams?")
    var grams: Double

    @Parameter(title: "Price Per Gram", requestValueDialog: "At what price per gram?")
    var pricePerGram: Double

    @Parameter(title: "Bank Account", requestValueDialog: "From which bank account?")
    var bankAccount: AccountEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let commodityId = commodity.id
        let bankAccountId = bankAccount.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let commodityInfo = try? context.fetch(FetchDescriptor<CommodityInfo>(predicate: #Predicate { $0.id == commodityId })).first else {
                throw IntentError.failed("Commodity not found.")
            }
            guard let bank = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankAccountId })).first else {
                throw IntentError.failed("Bank account not found.")
            }

            let gramsDecimal = Decimal(grams)
            let priceDecimal = Decimal(pricePerGram)
            let total = gramsDecimal * priceDecimal
            let symbol = commodityInfo.name.localizedCaseInsensitiveContains("gold") ? "XAU" : "XAG"

            let allHoldings = (try? context.fetch(FetchDescriptor<CommodityHolding>())) ?? []
            let holding: CommodityHolding
            if let existing = allHoldings.first(where: { $0.symbol == symbol }) {
                holding = existing
            } else {
                let rate = commodityInfo.currentRatePerGram > 0 ? commodityInfo.currentRatePerGram : 0
                holding = CommodityHolding(commodityName: commodityInfo.name, symbol: symbol, currentPricePerGram: rate)
                if rate > 0 { holding.priceFetchedAt = Date() }
                context.insert(holding)
            }

            let trade = CommodityTrade(
                holdingId: holding.id, type: .buy,
                commodityName: commodityInfo.name, symbol: symbol,
                grams: gramsDecimal, pricePerGram: priceDecimal,
                totalAmount: total, brokerageFee: 0, tax: 0, netAmount: total,
                date: date ?? Date(), notes: notes
            )
            context.insert(trade)

            let update = TradeService.weightedAverageBuy(
                currentQuantity: holding.totalGrams, currentCost: holding.totalCost,
                currentFees: holding.totalFeesPaid, addedQuantity: gramsDecimal,
                addedCost: total, addedFees: 0)
            holding.totalGrams = update.quantity; holding.totalCost = update.cost
            holding.totalFeesPaid = update.fees; holding.avgCostPerGram = update.avgCost

            bank.currentBalance -= total
            bank.updatedAt = Date()

            let tx = Transaction(type: .commodityBuy, amount: total, date: date ?? Date(),
                                 description: notes ?? "Buy \(commodityInfo.name)", fromAccountId: bank.id)
            context.insert(tx)
            let entry = LedgerEntry(transactionId: tx.id, accountId: bank.id, entryType: .debit,
                                    amount: total, runningBalance: bank.currentBalance, date: date ?? Date())
            context.insert(entry)
            trade.transactionId = tx.id
            try context.save()

            return .result(dialog: "Bought \(grams)g of \(commodityInfo.name) for Rs \(total.formatted(.number.precision(.fractionLength(0...2)))).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
