import Foundation
import AppIntents
import SwiftData

struct SellCommodityIntent: AppIntent {
    static var title: LocalizedStringResource = "Sell Commodity"
    static var description: LocalizedStringResource = "Sell gold or silver"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Commodity", requestValueDialog: "Which commodity?")
    var commodity: CommodityEntity

    @Parameter(title: "Grams", requestValueDialog: "How many grams?")
    var grams: Double

    @Parameter(title: "Price Per Gram", requestValueDialog: "At what price per gram?")
    var pricePerGram: Double

    @Parameter(title: "Bank Account", requestValueDialog: "To which bank account?")
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
            guard let holding = allHoldings.first(where: { $0.symbol == symbol && $0.totalGrams > 0 }) else {
                throw IntentError.failed("No \(commodityInfo.name) holdings to sell.")
            }
            guard gramsDecimal <= holding.totalGrams else {
                throw IntentError.failed("You only have \(holding.totalGrams.formatted(.number.precision(.fractionLength(2))))g.")
            }

            if holding.currentPricePerGram == nil || holding.currentPricePerGram == 0,
               commodityInfo.currentRatePerGram > 0 {
                holding.currentPricePerGram = commodityInfo.currentRatePerGram
                holding.priceFetchedAt = Date()
            }

            let trade = CommodityTrade(
                holdingId: holding.id, type: .sell,
                commodityName: commodityInfo.name, symbol: symbol,
                grams: gramsDecimal, pricePerGram: priceDecimal,
                totalAmount: total, brokerageFee: 0, tax: 0, netAmount: total,
                date: date ?? Date(), notes: notes
            )
            context.insert(trade)

            let update = TradeService.weightedAverageSell(
                currentQuantity: holding.totalGrams, currentCost: holding.totalCost,
                currentFees: holding.totalFeesPaid, soldQuantity: gramsDecimal)
            holding.totalGrams = update.quantity; holding.totalCost = update.cost
            holding.totalFeesPaid = update.fees; holding.avgCostPerGram = update.avgCost

            bank.currentBalance += total
            bank.updatedAt = Date()

            let tx = Transaction(type: .commoditySell, amount: total, date: date ?? Date(),
                                 description: notes ?? "Sell \(commodityInfo.name)", toAccountId: bank.id)
            context.insert(tx)
            let entry = LedgerEntry(transactionId: tx.id, accountId: bank.id, entryType: .credit,
                                    amount: total, runningBalance: bank.currentBalance, date: date ?? Date())
            context.insert(entry)
            trade.transactionId = tx.id
            try context.save()

            return .result(dialog: "Sold \(grams)g of \(commodityInfo.name) for Rs \(total.formatted(.number.precision(.fractionLength(0...2)))).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
