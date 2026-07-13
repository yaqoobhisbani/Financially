import Foundation
import SwiftData

struct LedgerManager {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func deleteTransaction(_ transaction: Transaction) throws {
        let txnId = transaction.id
        reverseLedgerEntries(txnId: txnId)
        reverseAccountBalances(for: transaction)
        reverseRelatedEntity(for: transaction)
        reverseTrade(for: transaction)
        modelContext.delete(transaction)
        try modelContext.save()
    }

    // MARK: - Reverse Ledger Entries

    private func reverseLedgerEntries(txnId: UUID) {
        let fetch = FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.transactionId == txnId })
        guard let entries = try? modelContext.fetch(fetch) else { return }
        for entry in entries {
            modelContext.delete(entry)
        }
    }

    // MARK: - Reverse Account Balances

    private func reverseAccountBalances(for transaction: Transaction) {
        let amount = transaction.amount

        let source: Account? = {
            guard let id = transaction.fromAccountId else { return nil }
            let fetch = FetchDescriptor<Account>(predicate: #Predicate { $0.id == id })
            return try? modelContext.fetch(fetch).first
        }()

        let destination: Account? = {
            guard let id = transaction.toAccountId else { return nil }
            let fetch = FetchDescriptor<Account>(predicate: #Predicate { $0.id == id })
            return try? modelContext.fetch(fetch).first
        }()

        switch transaction.type {
        case .expense:
            source?.currentBalance += amount
        case .income:
            // Income is recorded against the source account (fromAccountId), so its
            // balance is what must be decremented on reversal — mirroring LedgerService.
            source?.currentBalance -= amount
        case .transfer:
            source?.currentBalance += amount
            destination?.currentBalance -= amount
        case .loanGiven:
            source?.currentBalance += amount
        case .loanRepayment:
            destination?.currentBalance -= amount
        case .liabilityReceived:
            destination?.currentBalance -= amount
        case .liabilityPayback:
            source?.currentBalance += amount
        case .investmentAddCapital:
            source?.currentBalance += amount
            destination?.currentBalance -= amount
        case .investmentWithdrawal:
            destination?.currentBalance -= amount
            source?.currentBalance += amount
        case .investmentProfitLoss:
            source?.totalProfitLoss -= amount

        case .committeeContribution:
            source?.currentBalance += amount

        case .committeePayout:
            destination?.currentBalance -= amount

        case .commodityBuy:
            source?.currentBalance += amount

        case .commoditySell:
            source?.currentBalance -= amount

        case .stockBuy, .mutualFundBuy:
            source?.currentBalance += amount

        case .stockSell, .mutualFundSell:
            destination?.currentBalance -= amount
        }

        source?.updatedAt = Date()
        destination?.updatedAt = Date()
    }

    // MARK: - Reverse Related Entity (Debtor/Creditor)

    private func reverseRelatedEntity(for transaction: Transaction) {
        guard let entityId = transaction.relatedEntityId else { return }

        switch transaction.type {
        case .loanGiven, .loanRepayment:
            let fetch = FetchDescriptor<Debtor>(predicate: #Predicate { $0.id == entityId })
            if let debtor = try? modelContext.fetch(fetch).first {
                if transaction.type == .loanGiven {
                    debtor.totalLent -= transaction.amount
                } else {
                    debtor.totalRepaid -= transaction.amount
                }
                debtor.updatedAt = Date()
            }
        case .liabilityReceived, .liabilityPayback:
            let fetch = FetchDescriptor<Creditor>(predicate: #Predicate { $0.id == entityId })
            if let creditor = try? modelContext.fetch(fetch).first {
                if transaction.type == .liabilityReceived {
                    creditor.totalReceived -= transaction.amount
                } else {
                    creditor.totalReturned -= transaction.amount
                }
                creditor.updatedAt = Date()
            }
        default:
            break
        }
    }

    // MARK: - Reverse Trade (Stock/Commodity/Mutual Fund Holdings)

    private func reverseTrade(for transaction: Transaction) {
        let txnId = transaction.id

        switch transaction.type {
        case .stockBuy, .stockSell:
            let fetch = FetchDescriptor<StockTrade>(predicate: #Predicate { $0.transactionId == txnId })
            guard let trade = try? modelContext.fetch(fetch).first else { return }
            let holdingId = trade.holdingId
            let accountId = trade.accountId
            modelContext.delete(trade)

            let holdingFetch = FetchDescriptor<StockHolding>(predicate: #Predicate { $0.id == holdingId })
            guard let holding = try? modelContext.fetch(holdingFetch).first else { return }

            let tradesFetch = FetchDescriptor<StockTrade>(predicate: #Predicate { $0.holdingId == holdingId })
            let remaining = (try? modelContext.fetch(tradesFetch)) ?? []
            let result = TradeService.recalculateStockHolding(trades: remaining)
            holding.totalShares = result.totalShares
            holding.totalCost = result.totalCost
            holding.totalFeesPaid = result.totalFeesPaid
            holding.avgCostPerShare = result.avgCostPerShare

            let accountFetch = FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountId })
            if let account = try? modelContext.fetch(accountFetch).first {
                let allHoldingsFetch = FetchDescriptor<StockHolding>(predicate: #Predicate { $0.accountId == accountId })
                let allHoldings = (try? modelContext.fetch(allHoldingsFetch)) ?? []
                account.syncFromHoldings(allHoldings)
                account.updatedAt = Date()
            }

        case .mutualFundBuy, .mutualFundSell:
            let fetch = FetchDescriptor<MutualFundTrade>(predicate: #Predicate { $0.transactionId == txnId })
            guard let trade = try? modelContext.fetch(fetch).first else { return }
            let holdingId = trade.holdingId
            let accountId = trade.accountId
            modelContext.delete(trade)

            let holdingFetch = FetchDescriptor<MutualFundHolding>(predicate: #Predicate { $0.id == holdingId })
            guard let holding = try? modelContext.fetch(holdingFetch).first else { return }

            let tradesFetch = FetchDescriptor<MutualFundTrade>(predicate: #Predicate { $0.holdingId == holdingId })
            let remaining = (try? modelContext.fetch(tradesFetch)) ?? []
            let result = TradeService.recalculateMFHolding(trades: remaining)
            holding.totalUnits = result.totalUnits
            holding.totalCost = result.totalCost
            holding.avgNavPrice = result.avgNavPrice

            let accountFetch = FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountId })
            if let account = try? modelContext.fetch(accountFetch).first {
                let allHoldingsFetch = FetchDescriptor<MutualFundHolding>(predicate: #Predicate { $0.accountId == accountId })
                let allHoldings = (try? modelContext.fetch(allHoldingsFetch)) ?? []
                account.syncFromMFHoldings(allHoldings)
                account.updatedAt = Date()
            }

        case .commodityBuy, .commoditySell:
            let fetch = FetchDescriptor<CommodityTrade>(predicate: #Predicate { $0.transactionId == txnId })
            guard let trade = try? modelContext.fetch(fetch).first else { return }
            let holdingId = trade.holdingId
            modelContext.delete(trade)

            let holdingFetch = FetchDescriptor<CommodityHolding>(predicate: #Predicate { $0.id == holdingId })
            guard let holding = try? modelContext.fetch(holdingFetch).first else { return }

            let tradesFetch = FetchDescriptor<CommodityTrade>(predicate: #Predicate { $0.holdingId == holdingId })
            let remaining = (try? modelContext.fetch(tradesFetch)) ?? []
            let result = TradeService.recalculateCommodityHolding(trades: remaining)
            holding.totalGrams = result.totalGrams
            holding.totalCost = result.totalCost
            holding.totalFeesPaid = result.totalFeesPaid
            holding.avgCostPerGram = result.avgCostPerGram

        default:
            break
        }
    }
}
