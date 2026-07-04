import Foundation
import SwiftData

struct TransactionRequest {
    var type: TransactionType
    var amount: Decimal
    var date: Date
    var category: String?
    var description: String?
    var sourceAccountId: UUID
    var destinationAccountId: UUID?
    var relatedEntityId: UUID?
}

struct LedgerService {

    private let modelContext: ModelContext
    private let validator: TransactionValidator

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.validator = TransactionValidator(modelContext: modelContext)
    }

    func execute(_ request: TransactionRequest) throws {
        guard let sourceAccount = fetchAccount(request.sourceAccountId) else {
            throw ValidationError.accountNotFound(request.sourceAccountId)
        }

        var destinationAccount: Account?
        if let destId = request.destinationAccountId {
            destinationAccount = fetchAccount(destId)
            guard destinationAccount != nil else {
                throw ValidationError.accountNotFound(destId)
            }
        }

        let transaction = Transaction(
            type: request.type,
            amount: request.amount,
            date: request.date,
            category: request.category,
            description: request.description,
            fromAccountId: request.sourceAccountId,
            toAccountId: request.destinationAccountId,
            relatedEntityId: request.relatedEntityId
        )

        try validator.validate(
            transaction: transaction,
            accounts: sourceAccount,
            destination: destinationAccount
        )

        modelContext.insert(transaction)

        switch request.type {
        case .expense:
            createExpenseEntries(transaction: transaction, source: sourceAccount)

        case .income:
            createIncomeEntries(transaction: transaction, destination: sourceAccount)

        case .transfer:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createTransferEntries(transaction: transaction, source: sourceAccount, destination: dest)

        case .investmentAddCapital:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createAddCapitalEntries(transaction: transaction, source: sourceAccount, investment: dest)

        case .investmentWithdrawal:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createWithdrawalEntries(transaction: transaction, investment: sourceAccount, destination: dest)

        case .loanGiven:
            createLoanGivenEntries(transaction: transaction, source: sourceAccount)

        case .loanRepayment:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createLoanRepaymentEntries(transaction: transaction, destination: dest)

        case .liabilityReceived:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createLiabilityReceivedEntries(transaction: transaction, destination: dest)

        case .liabilityPayback:
            createLiabilityPaybackEntries(transaction: transaction, source: sourceAccount)

        case .investmentProfitLoss:
            createProfitLossEntries(transaction: transaction, investment: sourceAccount)

        case .committeeContribution:
            createExpenseEntries(transaction: transaction, source: sourceAccount)

        case .committeePayout:
            guard let dest = destinationAccount else { throw ValidationError.accountNotFound(UUID()) }
            createIncomeEntries(transaction: transaction, destination: dest)
        }

        sourceAccount.updatedAt = Date()
        destinationAccount?.updatedAt = Date()
    }

    // MARK: - Entry Creators

    private func createExpenseEntries(transaction: Transaction, source: Account) {
        let sourceRunningBalance = source.currentBalance - transaction.amount
        source.currentBalance = sourceRunningBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: source.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceRunningBalance,
            date: transaction.date
        )
        debit.account = source
        modelContext.insert(debit)
    }

    private func createIncomeEntries(transaction: Transaction, destination: Account) {
        let destRunningBalance = destination.currentBalance + transaction.amount
        destination.currentBalance = destRunningBalance

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: destination.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destRunningBalance,
            date: transaction.date
        )
        credit.account = destination
        modelContext.insert(credit)
    }

    private func createTransferEntries(transaction: Transaction, source: Account, destination: Account) {
        let sourceBalance = source.currentBalance - transaction.amount
        source.currentBalance = sourceBalance

        let destBalance = destination.currentBalance + transaction.amount
        destination.currentBalance = destBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: source.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceBalance,
            date: transaction.date
        )
        debit.account = source
        modelContext.insert(debit)

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: destination.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destBalance,
            date: transaction.date
        )
        credit.account = destination
        modelContext.insert(credit)
    }

    private func createAddCapitalEntries(transaction: Transaction, source: Account, investment: Account) {
        let sourceBalance = source.currentBalance - transaction.amount
        source.currentBalance = sourceBalance

        let destBalance = investment.currentBalance + transaction.amount
        investment.currentBalance = destBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: source.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceBalance,
            date: transaction.date
        )
        debit.account = source
        modelContext.insert(debit)

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: investment.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destBalance,
            date: transaction.date
        )
        credit.account = investment
        modelContext.insert(credit)
    }

    private func createWithdrawalEntries(transaction: Transaction, investment: Account, destination: Account) {
        let sourceBalance = investment.currentBalance - transaction.amount
        investment.currentBalance = sourceBalance

        let destBalance = destination.currentBalance + transaction.amount
        destination.currentBalance = destBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: investment.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceBalance,
            date: transaction.date
        )
        debit.account = investment
        modelContext.insert(debit)

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: destination.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destBalance,
            date: transaction.date
        )
        credit.account = destination
        modelContext.insert(credit)
    }

    private func createLoanGivenEntries(transaction: Transaction, source: Account) {
        let sourceBalance = source.currentBalance - transaction.amount
        source.currentBalance = sourceBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: source.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceBalance,
            date: transaction.date
        )
        debit.account = source
        modelContext.insert(debit)
    }

    private func createLoanRepaymentEntries(transaction: Transaction, destination: Account) {
        let destBalance = destination.currentBalance + transaction.amount
        destination.currentBalance = destBalance

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: destination.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destBalance,
            date: transaction.date
        )
        credit.account = destination
        modelContext.insert(credit)
    }

    private func createLiabilityReceivedEntries(transaction: Transaction, destination: Account) {
        let destBalance = destination.currentBalance + transaction.amount
        destination.currentBalance = destBalance

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: destination.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: destBalance,
            date: transaction.date
        )
        credit.account = destination
        modelContext.insert(credit)
    }

    private func createLiabilityPaybackEntries(transaction: Transaction, source: Account) {
        let sourceBalance = source.currentBalance - transaction.amount
        source.currentBalance = sourceBalance

        let debit = LedgerEntry(
            transactionId: transaction.id,
            accountId: source.id,
            entryType: .debit,
            amount: transaction.amount,
            runningBalance: sourceBalance,
            date: transaction.date
        )
        debit.account = source
        modelContext.insert(debit)
    }

    private func createProfitLossEntries(transaction: Transaction, investment: Account) {
        investment.totalProfitLoss += transaction.amount

        let credit = LedgerEntry(
            transactionId: transaction.id,
            accountId: investment.id,
            entryType: .credit,
            amount: transaction.amount,
            runningBalance: investment.currentValue,
            date: transaction.date
        )
        credit.account = investment
        modelContext.insert(credit)
    }

    private func fetchAccount(_ id: UUID) -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
}