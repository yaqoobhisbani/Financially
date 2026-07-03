import Foundation
import SwiftData

enum ValidationError: Error {
    case insufficientBalance(accountName: String, available: Decimal, needed: Decimal)
    case investmentWithdrawalCap(accountName: String, currentValue: Decimal, requested: Decimal)
    case invalidWithdrawalDestination
    case amountMustBePositive
    case accountNotFound(UUID)
    case accountNotActive(UUID)
    case selfTransfer
    case transferToInvestmentAccount
    case repaymentExceedsOutstanding(debtorName: String, outstanding: Decimal, attempted: Decimal)
    case paybackExceedsOutstanding(creditorName: String, outstanding: Decimal, attempted: Decimal)
    case futureDateNotAllowed
    case accountTypeMismatch
}

struct TransactionValidator {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func validate(transaction: Transaction, accounts sourceAccount: Account, destination destinationAccount: Account? = nil) throws(ValidationError) {
        guard transaction.amount > 0 else {
            throw .amountMustBePositive
        }

        guard transaction.date <= Date() else {
            throw .futureDateNotAllowed
        }

        guard sourceAccount.isActive else {
            throw .accountNotActive(sourceAccount.id)
        }

        if let destination = destinationAccount {
            guard destination.isActive else {
                throw .accountNotActive(destination.id)
            }
        }

        switch transaction.type {
        case .expense:
            guard sourceAccount.accountType == .bank || sourceAccount.accountType == .cash else {
                throw .accountTypeMismatch
            }
            try validateSufficientBalance(account: sourceAccount, amount: transaction.amount)

        case .income:
            guard sourceAccount.accountType == .bank || sourceAccount.accountType == .cash else {
                throw .accountTypeMismatch
            }

        case .transfer:
            guard let dest = destinationAccount else { throw .accountNotFound(UUID()) }
            guard sourceAccount.id != dest.id else { throw .selfTransfer }
            guard dest.accountType == .bank || dest.accountType == .cash else {
                throw .transferToInvestmentAccount
            }
            try validateSufficientBalance(account: sourceAccount, amount: transaction.amount)

        case .investmentAddCapital:
            guard let dest = destinationAccount else { throw .accountNotFound(UUID()) }
            guard dest.accountType == .psx || dest.accountType == .mutualFund else {
                throw .accountTypeMismatch
            }
            guard sourceAccount.accountType == .bank || sourceAccount.accountType == .cash else {
                throw .accountTypeMismatch
            }
            try validateSufficientBalance(account: sourceAccount, amount: transaction.amount)

        case .investmentWithdrawal:
            guard sourceAccount.accountType == .psx || sourceAccount.accountType == .mutualFund else {
                throw .accountTypeMismatch
            }
            guard let dest = destinationAccount else { throw .accountNotFound(UUID()) }
            guard dest.accountType == .bank || dest.accountType == .cash else {
                throw .invalidWithdrawalDestination
            }
            guard transaction.amount <= sourceAccount.currentValue else {
                throw .investmentWithdrawalCap(accountName: sourceAccount.name, currentValue: sourceAccount.currentValue, requested: transaction.amount)
            }

        case .loanGiven:
            guard sourceAccount.accountType == .bank || sourceAccount.accountType == .cash else {
                throw .accountTypeMismatch
            }
            try validateSufficientBalance(account: sourceAccount, amount: transaction.amount)

        case .loanRepayment:
            guard let dest = destinationAccount else { throw .accountNotFound(UUID()) }
            guard dest.accountType == .bank || dest.accountType == .cash else {
                throw .accountTypeMismatch
            }

        case .liabilityReceived:
            guard let dest = destinationAccount else { throw .accountNotFound(UUID()) }
            guard dest.accountType == .bank || dest.accountType == .cash else {
                throw .accountTypeMismatch
            }

        case .liabilityPayback:
            guard sourceAccount.accountType == .bank || sourceAccount.accountType == .cash else {
                throw .accountTypeMismatch
            }
            try validateSufficientBalance(account: sourceAccount, amount: transaction.amount)

        case .investmentProfitLoss:
            guard sourceAccount.accountType == .psx || sourceAccount.accountType == .mutualFund else {
                throw .accountTypeMismatch
            }
        }
    }

    private func validateSufficientBalance(account: Account, amount: Decimal) throws(ValidationError) {
        guard account.currentBalance >= amount else {
            throw .insufficientBalance(accountName: account.name, available: account.currentBalance, needed: amount)
        }
    }

    func validateRepayment(amount: Decimal, debtor: Debtor) throws(ValidationError) {
        guard amount <= debtor.outstandingBalance else {
            throw .repaymentExceedsOutstanding(debtorName: debtor.name, outstanding: debtor.outstandingBalance, attempted: amount)
        }
    }

    func validatePayback(amount: Decimal, creditor: Creditor) throws(ValidationError) {
        guard amount <= creditor.outstandingBalance else {
            throw .paybackExceedsOutstanding(creditorName: creditor.name, outstanding: creditor.outstandingBalance, attempted: amount)
        }
    }
}