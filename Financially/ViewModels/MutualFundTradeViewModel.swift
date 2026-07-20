import Foundation
import SwiftData

@Observable
final class MutualFundTradeViewModel {
    private let modelContext: ModelContext
    let account: Account
    let schemeList: [MutualFundScheme]
    let holdings: [MutualFundHolding]

    init(modelContext: ModelContext, account: Account, schemeList: [MutualFundScheme], holdings: [MutualFundHolding]) {
        self.modelContext = modelContext
        self.account = account
        self.schemeList = schemeList
        self.holdings = holdings
    }

    var accountHoldings: [MutualFundHolding] {
        holdings.filter { $0.accountId == account.id && $0.totalUnits > 0 }
    }

    func findOrCreateHolding(fundCode: String, schemeName: String) -> MutualFundHolding {
        if let existing = holdings.first(where: { $0.fundCode == fundCode && $0.accountId == account.id }) {
            return existing
        }
        let holding = MutualFundHolding(accountId: account.id, schemeName: schemeName, fundCode: fundCode)
        modelContext.insert(holding)
        return holding
    }

    func invest(
        bankAccount: Account?,
        scheme: MutualFundScheme,
        units: Decimal,
        navPrice: Decimal,
        fees: Decimal,
        tax: Decimal = 0,
        date: Date,
        notes: String?
    ) {
        let netAmount = units * navPrice + fees + tax

        if let bank = bankAccount {
            bank.currentBalance -= netAmount
            bank.updatedAt = Date()
        }

        let holding = findOrCreateHolding(fundCode: scheme.fundCode, schemeName: scheme.schemeName)

        if scheme.navPrice > 0 {
            holding.currentNavPrice = scheme.navPrice
            holding.priceFetchedAt = Date()
        }

        let update = TradeService.weightedAverageBuy(
            currentQuantity: holding.totalUnits,
            currentCost: holding.totalCost,
            currentFees: 0,
            addedQuantity: units,
            addedCost: units * navPrice,
            addedFees: fees + tax
        )
        holding.totalUnits = update.quantity
        holding.totalCost = update.cost
        holding.avgNavPrice = update.avgCost

        let trade = MutualFundTrade(
            accountId: account.id,
            holdingId: holding.id,
            type: .buy,
            fundCode: scheme.fundCode,
            schemeName: scheme.schemeName,
            units: units,
            navPrice: navPrice,
            totalAmount: units * navPrice,
            fees: fees,
            tax: tax,
            netAmount: netAmount,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let description = notes ?? "Invest in \(scheme.schemeName)"
        let transaction = createTransaction(type: .mutualFundBuy, amount: netAmount, date: date, description: description, bankAccountId: bankAccount?.id)
        trade.transactionId = transaction.id

        syncAccountFromHoldings()
        account.updatedAt = Date()
    }

    func redeem(
        holding: MutualFundHolding,
        units: Decimal,
        navPrice: Decimal,
        fees: Decimal,
        tax: Decimal = 0,
        bankAccount: Account,
        date: Date,
        notes: String?
    ) {
        let netProceeds = units * navPrice - fees - tax

        bankAccount.currentBalance += netProceeds
        bankAccount.updatedAt = Date()

        let update = TradeService.weightedAverageSell(
            currentQuantity: holding.totalUnits,
            currentCost: holding.totalCost,
            currentFees: 0,
            soldQuantity: units
        )
        holding.totalUnits = update.quantity
        holding.totalCost = update.cost
        holding.avgNavPrice = update.avgCost

        if let scheme = schemeList.first(where: { $0.fundCode == holding.fundCode }), scheme.navPrice > 0 {
            holding.currentNavPrice = scheme.navPrice
            holding.priceFetchedAt = Date()
        }

        let trade = MutualFundTrade(
            accountId: account.id,
            holdingId: holding.id,
            type: .sell,
            fundCode: holding.fundCode,
            schemeName: holding.schemeName,
            units: units,
            navPrice: navPrice,
            totalAmount: units * navPrice,
            fees: fees,
            tax: tax,
            netAmount: netProceeds,
            date: date,
            notes: notes
        )
        modelContext.insert(trade)

        let description = notes ?? "Redeem \(holding.schemeName)"
        let transaction = createTransaction(type: .mutualFundSell, amount: netProceeds, date: date, description: description, bankAccountId: bankAccount.id)
        trade.transactionId = transaction.id

        syncAccountFromHoldings()
        account.updatedAt = Date()
    }

    @discardableResult
    private func createTransaction(type: TransactionType, amount: Decimal, date: Date, description: String, bankAccountId: UUID?) -> Transaction {
        let transaction = Transaction(
            type: type,
            amount: amount,
            date: date,
            description: description,
            fromAccountId: type == .mutualFundBuy ? bankAccountId : account.id,
            toAccountId: type == .mutualFundSell ? bankAccountId : account.id,
            relatedEntityId: account.id
        )
        modelContext.insert(transaction)

        if let bankId = bankAccountId {
            let acctId = bankId
            let bank = try? modelContext.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == acctId })).first

            let entry = LedgerEntry(
                transactionId: transaction.id,
                accountId: bankId,
                entryType: type == .mutualFundBuy ? .debit : .credit,
                amount: amount,
                runningBalance: bank?.currentBalance ?? 0,
                date: date
            )
            entry.account = bank
            modelContext.insert(entry)
        }

        return transaction
    }

    private func syncAccountFromHoldings() {
        let all = (try? modelContext.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
        account.syncFromMFHoldings(all.filter { $0.accountId == account.id })
    }
}
