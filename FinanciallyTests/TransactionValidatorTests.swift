import Testing
import Foundation
@testable import Financially

@MainActor
@Suite("TransactionValidator")
struct TransactionValidatorTests {

    private func makeValidator() -> TransactionValidator {
        TransactionValidator(modelContext: TestSupport.makeContext())
    }

    private func makeTransaction(type: TransactionType, amount: Decimal, date: Date = Date()) -> Transaction {
        Transaction(type: type, amount: amount, date: date)
    }

    // MARK: - Universal guards

    @Test func rejectsZeroOrNegativeAmount() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let tx = makeTransaction(type: .expense, amount: 0)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func rejectsFutureDatedTransactions() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tx = makeTransaction(type: .expense, amount: 100, date: futureDate)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func rejectsInactiveSourceAccount() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000, isActive: false)
        let tx = makeTransaction(type: .expense, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func rejectsInactiveDestinationAccount() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let dest = Account(name: "Cash", accountType: .cash, isActive: false)
        let tx = makeTransaction(type: .transfer, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source, destination: dest)
        }
    }

    @Test func allowsNilSourceToPassThroughWithoutFurtherChecks() throws {
        // Transactions without a source account (e.g. "outside" flows) only need the universal guards.
        let validator = makeValidator()
        let tx = makeTransaction(type: .commodityBuy, amount: 100)
        try validator.validate(transaction: tx, accounts: nil)
    }

    // MARK: - Expense / Income

    @Test func expenseRequiresBankOrCashSource() {
        let validator = makeValidator()
        let source = Account(name: "PSX", accountType: .psx, initialBalance: 1000)
        let tx = makeTransaction(type: .expense, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func expenseRejectsInsufficientBalance() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 50)
        let tx = makeTransaction(type: .expense, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func expenseAllowsSufficientBalance() throws {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 200)
        let tx = makeTransaction(type: .expense, amount: 100)
        try validator.validate(transaction: tx, accounts: source)
    }

    @Test func incomeDoesNotRequireBalanceCheck() throws {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 0)
        let tx = makeTransaction(type: .income, amount: 5000)
        try validator.validate(transaction: tx, accounts: source)
    }

    // MARK: - Transfer

    @Test func transferRejectsSelfTransfer() {
        let validator = makeValidator()
        let account = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let tx = makeTransaction(type: .transfer, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: account, destination: account)
        }
    }

    @Test func transferRejectsInvestmentAccountDestination() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let dest = Account(name: "PSX", accountType: .psx)
        let tx = makeTransaction(type: .transfer, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source, destination: dest)
        }
    }

    @Test func transferSucceedsBetweenBankAndCash() throws {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let dest = Account(name: "Cash", accountType: .cash)
        let tx = makeTransaction(type: .transfer, amount: 100)
        try validator.validate(transaction: tx, accounts: source, destination: dest)
    }

    // MARK: - Investment add capital / withdrawal

    @Test func addCapitalRequiresPSXDestination() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 1000)
        let dest = Account(name: "Cash", accountType: .cash)
        let tx = makeTransaction(type: .investmentAddCapital, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source, destination: dest)
        }
    }

    @Test func withdrawalRejectsAmountAboveCurrentValue() {
        let validator = makeValidator()
        let source = Account(name: "PSX", accountType: .psx, investedAmount: 500, totalProfitLoss: 0)
        let dest = Account(name: "Bank", accountType: .bank)
        let tx = makeTransaction(type: .investmentWithdrawal, amount: 1000)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source, destination: dest)
        }
    }

    @Test func withdrawalRejectsNonBankCashDestination() {
        let validator = makeValidator()
        let source = Account(name: "PSX", accountType: .psx, investedAmount: 1000)
        let dest = Account(name: "MF", accountType: .mutualFund)
        let tx = makeTransaction(type: .investmentWithdrawal, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source, destination: dest)
        }
    }

    @Test func withdrawalAllowsAmountWithinCurrentValue() throws {
        let validator = makeValidator()
        let source = Account(name: "PSX", accountType: .psx, investedAmount: 1000, totalProfitLoss: 0)
        let dest = Account(name: "Bank", accountType: .bank)
        let tx = makeTransaction(type: .investmentWithdrawal, amount: 500)
        try validator.validate(transaction: tx, accounts: source, destination: dest)
    }

    // MARK: - Loans / Liabilities

    @Test func loanGivenRejectsInsufficientBalance() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 10)
        let tx = makeTransaction(type: .loanGiven, amount: 1000)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    @Test func liabilityPaybackRejectsInsufficientBalance() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank, initialBalance: 10)
        let tx = makeTransaction(type: .liabilityPayback, amount: 1000)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    // MARK: - investmentProfitLoss

    @Test func profitLossRequiresPSXSource() {
        let validator = makeValidator()
        let source = Account(name: "Bank", accountType: .bank)
        let tx = makeTransaction(type: .investmentProfitLoss, amount: 100)
        #expect(throws: ValidationError.self) {
            try validator.validate(transaction: tx, accounts: source)
        }
    }

    // MARK: - Repayment / Payback caps (dedicated validator methods)

    @Test func validateRepaymentRejectsAmountExceedingOutstanding() {
        let validator = makeValidator()
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 800)
        #expect(throws: ValidationError.self) {
            try validator.validateRepayment(amount: 500, debtor: debtor)
        }
    }

    @Test func validateRepaymentAllowsAmountWithinOutstanding() throws {
        let validator = makeValidator()
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 800)
        try validator.validateRepayment(amount: 200, debtor: debtor)
    }

    @Test func validatePaybackRejectsAmountExceedingOutstanding() {
        let validator = makeValidator()
        let creditor = Creditor(name: "Sana", totalReceived: 1000, totalReturned: 500)
        #expect(throws: ValidationError.self) {
            try validator.validatePayback(amount: 600, creditor: creditor)
        }
    }

    @Test func validatePaybackAllowsAmountWithinOutstanding() throws {
        let validator = makeValidator()
        let creditor = Creditor(name: "Sana", totalReceived: 1000, totalReturned: 500)
        try validator.validatePayback(amount: 500, creditor: creditor)
    }
}
