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
            destination?.currentBalance -= amount
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

        case .stockBuy, .stockSell:
            break
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
}
