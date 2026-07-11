import Foundation
import AppIntents
import SwiftData

struct IntentError: Error, CustomLocalizedStringResourceConvertible {
    let message: String

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: message)
    }

    static func failed(_ message: String) -> Self { .init(message: message) }
}

func errorMessage(from error: ValidationError) -> String {
    switch error {
    case .insufficientBalance(let n, _, _): return "Insufficient balance in \(n)."
    case .amountMustBePositive: return "Amount must be positive."
    case .accountNotFound: return "Account not found."
    case .accountNotActive: return "Account is not active."
    case .accountTypeMismatch: return "Please select a bank or cash account."
    case .futureDateNotAllowed: return "Date cannot be in the future."
    case .selfTransfer: return "Source and destination must be different."
    case .transferToInvestmentAccount: return "Cannot transfer to an investment account."
    default: return "Validation failed."
    }
}

@discardableResult
func insertStockTransaction(context: ModelContext, type: TransactionType, amount: Decimal, date: Date, description: String, psxAccountId: UUID, psxAccountBalance: Decimal) -> Transaction {
    let tx = Transaction(
        type: type, amount: amount, date: date, description: description,
        fromAccountId: type == .stockBuy ? psxAccountId : nil,
        toAccountId: type == .stockSell ? psxAccountId : nil,
        relatedEntityId: psxAccountId
    )
    context.insert(tx)
    let entry = LedgerEntry(
        transactionId: tx.id, accountId: psxAccountId,
        entryType: type == .stockBuy ? .debit : .credit,
        amount: amount, runningBalance: psxAccountBalance, date: date
    )
    context.insert(entry)
    return tx
}
