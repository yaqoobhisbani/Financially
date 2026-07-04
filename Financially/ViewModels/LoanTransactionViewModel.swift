import Foundation
import SwiftData

@Observable
final class LoanTransactionViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    enum LoanError: LocalizedError {
        case invalidAmount
        case exceedsBalance(label: String)
        case noAccountSelected

        var errorDescription: String? {
            switch self {
            case .invalidAmount: return "Please enter a valid amount"
            case .exceedsBalance(let label): return "\(label) exceeds outstanding balance"
            case .noAccountSelected: return "Please select an account"
            }
        }
    }

    func giveLoan(to debtor: Debtor, amount: Decimal, date: Date, description: String?, sourceAccountId: UUID) throws {
        debtor.totalLent += amount
        debtor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .loanGiven,
            amount: amount,
            date: date,
            description: description,
            sourceAccountId: sourceAccountId,
            relatedEntityId: debtor.id
        )
        do {
            try service.execute(request)
        } catch {
            debtor.totalLent -= amount
            throw error
        }
    }

    func recordRepayment(from debtor: Debtor, amount: String, date: Date, description: String?, destinationAccountId: UUID) throws {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            throw LoanError.invalidAmount
        }

        debtor.totalRepaid += amountValue
        debtor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .loanRepayment,
            amount: amountValue,
            date: date,
            description: description,
            sourceAccountId: destinationAccountId,
            destinationAccountId: destinationAccountId,
            relatedEntityId: debtor.id
        )
        do {
            try service.execute(request)
        } catch {
            debtor.totalRepaid -= amountValue
            throw error
        }
    }

    func receiveMoney(from creditor: Creditor, amount: String, date: Date, description: String?, destinationAccountId: UUID) throws {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            throw LoanError.invalidAmount
        }

        creditor.totalReceived += amountValue
        creditor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .liabilityReceived,
            amount: amountValue,
            date: date,
            description: description,
            sourceAccountId: destinationAccountId,
            destinationAccountId: destinationAccountId,
            relatedEntityId: creditor.id
        )
        do {
            try service.execute(request)
        } catch {
            creditor.totalReceived -= amountValue
            throw error
        }
    }

    func payBack(to creditor: Creditor, amount: String, date: Date, description: String?, sourceAccountId: UUID) throws {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            throw LoanError.invalidAmount
        }

        creditor.totalReturned += amountValue
        creditor.updatedAt = Date()

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .liabilityPayback,
            amount: amountValue,
            date: date,
            description: description,
            sourceAccountId: sourceAccountId,
            relatedEntityId: creditor.id
        )
        do {
            try service.execute(request)
        } catch {
            creditor.totalReturned -= amountValue
            throw error
        }
    }
}