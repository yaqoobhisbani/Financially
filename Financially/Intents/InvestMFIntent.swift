import Foundation
import AppIntents
import SwiftData

struct InvestMFIntent: AppIntent {
    static var title: LocalizedStringResource = "Invest in Mutual Fund"
    static var description: LocalizedStringResource = "Invest in a mutual fund scheme"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "MF Account", requestValueDialog: "Which MF account?")
    var account: MFAccountEntity

    @Parameter(title: "Scheme", requestValueDialog: "Which scheme?")
    var scheme: MutualFundSchemeEntity

    @Parameter(title: "Units", requestValueDialog: "How many units?")
    var units: Double

    @Parameter(title: "NAV Price", requestValueDialog: "At what NAV price?")
    var navPrice: Double

    @Parameter(title: "Bank Account", requestValueDialog: "From which bank account?")
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

            let unitsDecimal = Decimal(units)
            let navPriceDecimal = Decimal(navPrice)
            let netAmount = unitsDecimal * navPriceDecimal

            bank.currentBalance -= netAmount
            bank.updatedAt = Date()

            let allHoldings = (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
            let holding: MutualFundHolding
            if let existing = allHoldings.first(where: { $0.fundCode == schemeInfo.fundCode && $0.accountId == acct.id }) {
                holding = existing
            } else {
                holding = MutualFundHolding(accountId: acct.id, schemeName: schemeInfo.schemeName, fundCode: schemeInfo.fundCode)
                context.insert(holding)
            }

            if schemeInfo.navPrice > 0 {
                holding.currentNavPrice = schemeInfo.navPrice
                holding.priceFetchedAt = Date()
            }

            let update = TradeService.weightedAverageBuy(
                currentQuantity: holding.totalUnits, currentCost: holding.totalCost,
                currentFees: 0, addedQuantity: unitsDecimal,
                addedCost: unitsDecimal * navPriceDecimal, addedFees: 0)
            holding.totalUnits = update.quantity; holding.totalCost = update.cost
            holding.avgNavPrice = update.avgCost

            let trade = MutualFundTrade(
                accountId: acct.id, holdingId: holding.id, type: .buy,
                fundCode: schemeInfo.fundCode, schemeName: schemeInfo.schemeName,
                units: unitsDecimal, navPrice: navPriceDecimal,
                totalAmount: unitsDecimal * navPriceDecimal, fees: 0, netAmount: netAmount,
                date: date ?? Date(), notes: notes
            )
            context.insert(trade)

            let desc = notes ?? "Invest in \(schemeInfo.schemeName)"
            let tx = Transaction(type: .mutualFundBuy, amount: netAmount, date: date ?? Date(),
                                 description: desc, fromAccountId: bank.id, relatedEntityId: acct.id)
            context.insert(tx)
            let entry = LedgerEntry(transactionId: tx.id, accountId: bank.id, entryType: .debit,
                                    amount: netAmount, runningBalance: bank.currentBalance, date: date ?? Date())
            context.insert(entry)

            let all = (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
            acct.syncFromMFHoldings(all.filter { $0.accountId == acct.id })
            acct.updatedAt = Date()
            try context.save()

            return .result(dialog: "Invested Rs \(netAmount.formatted(.number.precision(.fractionLength(0...2)))) in \(schemeInfo.schemeName).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
