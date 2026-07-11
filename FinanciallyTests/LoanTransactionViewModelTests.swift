import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("LoanTransactionViewModel")
struct LoanTransactionViewModelTests {

    @Test func giveLoanIncreasesDebtorTotalLentAndDebitsAccount() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let debtor = Debtor(name: "Ali")
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        try vm.giveLoan(to: debtor, amount: 300, date: Date(), description: nil, sourceAccountId: account.id)

        #expect(debtor.totalLent == 300)
        #expect(account.currentBalance == 700)
    }

    @Test func giveLoanRollsBackDebtorTotalWhenLedgerRejects() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10) // too little
        let debtor = Debtor(name: "Ali")
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        #expect(throws: (any Error).self) {
            try vm.giveLoan(to: debtor, amount: 300, date: Date(), description: nil, sourceAccountId: account.id)
        }
        #expect(debtor.totalLent == 0) // rolled back, not left at 300
    }

    @Test func recordRepaymentIncreasesDebtorTotalRepaidAndCreditsAccount() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 0)
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        try vm.recordRepayment(from: debtor, amount: "400", date: Date(), description: nil, destinationAccountId: account.id)

        #expect(debtor.totalRepaid == 400)
        #expect(account.currentBalance == 400)
    }

    @Test func recordRepaymentRejectsAmountExceedingOutstandingBalance() {
        // Regression: this used to only show a UI warning while still submitting the transaction.
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 900) // only 100 outstanding
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        #expect(throws: LoanTransactionViewModel.LoanError.self) {
            try vm.recordRepayment(from: debtor, amount: "500", date: Date(), description: nil, destinationAccountId: account.id)
        }
        #expect(debtor.totalRepaid == 900) // unchanged
        #expect(account.currentBalance == 0) // unchanged
    }

    @Test func recordRepaymentAllowsExactOutstandingAmount() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let debtor = Debtor(name: "Ali", totalLent: 1000, totalRepaid: 900)
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        try vm.recordRepayment(from: debtor, amount: "100", date: Date(), description: nil, destinationAccountId: account.id)

        #expect(debtor.outstandingBalance == 0)
        #expect(debtor.isSettled)
    }

    @Test func recordRepaymentRejectsInvalidAmountString() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank)
        let debtor = Debtor(name: "Ali", totalLent: 1000)
        context.insert(debtor)
        let vm = LoanTransactionViewModel(modelContext: context)

        #expect(throws: LoanTransactionViewModel.LoanError.self) {
            try vm.recordRepayment(from: debtor, amount: "not-a-number", date: Date(), description: nil, destinationAccountId: account.id)
        }
    }

    @Test func receiveMoneyIncreasesCreditorTotalReceivedAndCreditsAccount() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let creditor = Creditor(name: "Sana")
        context.insert(creditor)
        let vm = LoanTransactionViewModel(modelContext: context)

        try vm.receiveMoney(from: creditor, amount: "800", date: Date(), description: nil, destinationAccountId: account.id)

        #expect(creditor.totalReceived == 800)
        #expect(account.currentBalance == 800)
    }

    @Test func payBackRejectsAmountExceedingOutstandingBalance() {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let creditor = Creditor(name: "Sana", totalReceived: 500, totalReturned: 400) // only 100 outstanding
        context.insert(creditor)
        let vm = LoanTransactionViewModel(modelContext: context)

        #expect(throws: LoanTransactionViewModel.LoanError.self) {
            try vm.payBack(to: creditor, amount: "200", date: Date(), description: nil, sourceAccountId: account.id)
        }
        #expect(creditor.totalReturned == 400)
        #expect(account.currentBalance == 1000)
    }

    @Test func payBackWithinOutstandingBalanceSucceeds() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 1000)
        let creditor = Creditor(name: "Sana", totalReceived: 500, totalReturned: 400)
        context.insert(creditor)
        let vm = LoanTransactionViewModel(modelContext: context)

        try vm.payBack(to: creditor, amount: "100", date: Date(), description: nil, sourceAccountId: account.id)

        #expect(creditor.outstandingBalance == 0)
        #expect(account.currentBalance == 900)
    }
}
