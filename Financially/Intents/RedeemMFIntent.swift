import Foundation
import AppIntents
import SwiftData

struct RedeemMFIntent: AppIntent {
    static var title: LocalizedStringResource = "Redeem Mutual Fund"
    static var description: LocalizedStringResource = "Redeem mutual fund units"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "MF Account", requestValueDialog: "From which MF account?")
    var account: MFAccountEntity

    @Parameter(title: "Scheme", requestValueDialog: "Which scheme?")
    var scheme: MutualFundSchemeEntity

    @Parameter(title: "Units", requestValueDialog: "How many units?")
    var units: Double

    @Parameter(title: "NAV Price", requestValueDialog: "At what NAV price?")
    var navPrice: Double

    @Parameter(title: "Bank Account", requestValueDialog: "To which bank account?")
    var bankAccount: AccountEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let accountId = account.id
        let schemeId = scheme.id
        let bankAccountId = bankAccount.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let acct = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountId })).first else {
                throw IntentError.failed("MF account not found.")
            }
            guard let schemeInfo = try? context.fetch(FetchDescriptor<MutualFundScheme>(predicate: #Predicate { $0.id == schemeId })).first else {
                throw IntentError.failed("Scheme not found.")
            }
            guard let bank = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankAccountId })).first else {
                throw IntentError.failed("Bank account not found.")
            }

            let allHoldings = (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
            guard let holding = allHoldings.first(where: { $0.fundCode == schemeInfo.fundCode && $0.accountId == acct.id && $0.totalUnits > 0 }) else {
                throw IntentError.failed("No holdings found for this scheme.")
            }

            let unitsDecimal = Decimal(units)
            let navPriceDecimal = Decimal(navPrice)
            let netProceeds = unitsDecimal * navPriceDecimal

            guard unitsDecimal <= holding.totalUnits else {
                throw IntentError.failed("You only have \(holding.totalUnits.formatted(.number.precision(.fractionLength(4)))) units.")
            }

            bank.currentBalance += netProceeds
            bank.updatedAt = Date()

            let update = TradeService.weightedAverageSell(
                currentQuantity: holding.totalUnits, currentCost: holding.totalCost,
                currentFees: 0, soldQuantity: unitsDecimal)
            holding.totalUnits = update.quantity; holding.totalCost = update.cost
            holding.avgNavPrice = update.avgCost

            if schemeInfo.navPrice > 0 {
                holding.currentNavPrice = schemeInfo.navPrice
                holding.priceFetchedAt = Date()
            }

            let trade = MutualFundTrade(
                accountId: acct.id, holdingId: holding.id, type: .sell,
                fundCode: schemeInfo.fundCode, schemeName: schemeInfo.schemeName,
                units: unitsDecimal, navPrice: navPriceDecimal,
                totalAmount: unitsDecimal * navPriceDecimal, fees: 0, netAmount: netProceeds,
                date: date ?? Date(), notes: notes
            )
            context.insert(trade)

            let desc = notes ?? "Redeem \(schemeInfo.schemeName)"
            let tx = Transaction(type: .mutualFundSell, amount: netProceeds, date: date ?? Date(),
                                 description: desc, toAccountId: bank.id, relatedEntityId: acct.id)
            context.insert(tx)
            let entry = LedgerEntry(transactionId: tx.id, accountId: bank.id, entryType: .credit,
                                    amount: netProceeds, runningBalance: bank.currentBalance, date: date ?? Date())
            context.insert(entry)
            trade.transactionId = tx.id

            let all = (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
            acct.syncFromMFHoldings(all.filter { $0.accountId == acct.id })
            acct.updatedAt = Date()
            try context.save()

            return .result(dialog: "Redeemed \(units) units of \(schemeInfo.schemeName) for Rs \(netProceeds.formatted(.number.precision(.fractionLength(0...2)))).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
